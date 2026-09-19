defmodule Treby.Workers.DataPrivacyExportWorker do
  use Oban.Worker, queue: :default, max_attempts: 3

  alias Treby.Accounts.User
  alias Treby.DataPrivacy.Requests
  alias Treby.Repo

  @backoff_by_attempt %{2 => 60, 3 => 300}

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"data_privacy_request_id" => id}}) do
    request = Repo.get(Treby.DataPrivacy.DataPrivacyRequest, id)

    case request do
      nil ->
        {:discard, "data_privacy_request not found"}

      %{status: status} when status not in ["pending", "processing"] ->
        {:discard, "request already #{status}"}

      request ->
        do_export(request)
    end
  end

  def perform(%Oban.Job{args: args}) do
    id = args["data_privacy_request_id"] || args[:data_privacy_request_id]

    if id,
      do: perform(%Oban.Job{args: %{"data_privacy_request_id" => id}}),
      else: {:discard, "missing data_privacy_request_id"}
  end

  @impl Oban.Worker
  def backoff(%Oban.Job{attempt: attempt}), do: Map.get(@backoff_by_attempt, attempt, 300)

  defp do_export(request) do
    {:ok, _processing} = Requests.transition(request, "processing")

    try do
      {export_data, s3_keys} = Treby.DataPrivacy.ExportBuilder.build(request.tenant_id, request)

      json = Jason.encode!(export_data, pretty: true)

      tmp_dir = System.tmp_dir!()
      zip_name = "#{request.id}.zip"
      zip_path = Path.join(tmp_dir, zip_name)
      json_path = Path.join(tmp_dir, "#{request.id}.json")
      File.write!(json_path, json)

      # Collect S3 files to bundle (best-effort, skip missing)
      s3_entries =
        Enum.flat_map(s3_keys, fn key ->
          case fetch_s3_entry(request.tenant_id, key) do
            {:ok, content} -> [{String.to_charlist("resumes/" <> Path.basename(key)), content}]
            _ -> []
          end
        end)

      zip_entries = [{String.to_charlist("export.json"), json} | s3_entries]

      {:ok, _} = :zip.create(String.to_charlist(zip_path), zip_entries, [])

      zip_content = File.read!(zip_path)
      s3_key = "#{request.tenant_id}/data-privacy-exports/#{request.id}.zip"

      case Treby.Uploads.upload_file(request.tenant_id, s3_key, zip_content, "application/zip") do
        {:ok, _} ->
          expires_at = DateTime.add(DateTime.utc_now(), 7 * 24 * 60 * 60, :second)

          {:ok, ready} =
            Requests.transition(request, "ready", %{s3_key: s3_key, expires_at: expires_at})

          Treby.Audit.log_event("data_privacy.export_ready", "data_privacy_request", ready.id, %{
            tenant_id: ready.tenant_id,
            actor_id: ready.requester_id,
            metadata: %{type: "export", scope: ready.scope, s3_key: s3_key}
          })

          send_export_ready_email(ready)

          File.rm(json_path)
          File.rm(zip_path)
          :ok

        {:error, reason} ->
          File.rm(json_path)
          File.rm(zip_path)
          {:ok, _} = Requests.transition(request, "failed", %{error: inspect(reason)})
          {:error, reason}
      end
    rescue
      e ->
        {:ok, _} = Requests.transition(request, "failed", %{error: Exception.message(e)})
        {:error, Exception.message(e)}
    end
  end

  defp fetch_s3_entry(tenant_id, key) do
    case Treby.Uploads.get_file(tenant_id, key) do
      {:ok, %{body: body}} when is_binary(body) -> {:ok, body}
      {:ok, %{body: _} = resp} -> {:ok, Map.get(resp, :body, "")}
      {:error, _} -> :error
    end
  rescue
    _ -> :error
  end

  defp send_export_ready_email(request) do
    case Repo.get(User, request.requester_id) do
      nil ->
        :ok

      user ->
        email =
          Swoosh.Email.new()
          |> Swoosh.Email.to(user.email)
          |> Swoosh.Email.from({"Treby", "noreply@treby.app"})
          |> Swoosh.Email.subject("Your data export is ready")
          |> Swoosh.Email.text_body(
            "Your export is ready. Download at /#{request.tenant_id}/data-privacy/exports/#{request.id}/download — expires at #{request.expires_at} (signed URL valid 1 hour)."
          )

        case Treby.Mailer.deliver(email) do
          {:ok, _} -> :ok
          _ -> :ok
        end
    end
  rescue
    _ -> :ok
  end
end
