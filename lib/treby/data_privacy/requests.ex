defmodule Treby.DataPrivacy.Requests do
  import Ecto.Query, warn: false
  alias Treby.DataPrivacy.DataPrivacyRequest
  alias Treby.Repo

  def create_request(attrs, opts \\ []) do
    audit_attrs = Keyword.get(opts, :audit, %{})

    %DataPrivacyRequest{}
    |> DataPrivacyRequest.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, request} ->
        action =
          case request.type do
            "export" -> "data_privacy.export_requested"
            "erasure" -> "data_privacy.erasure_requested"
          end

        Treby.Audit.log_event(
          action,
          "data_privacy_request",
          request.id,
          %{
            tenant_id: request.tenant_id,
            actor_id: request.requester_id,
            metadata: %{type: request.type, scope: request.scope}
          }
          |> Map.merge(audit_attrs)
        )

        enqueue_worker(request)
        maybe_notify_erasure_request(request)
        {:ok, request}

      error ->
        error
    end
  end

  defp maybe_notify_erasure_request(
         %DataPrivacyRequest{type: "erasure", scope: "tenant"} = request
       ) do
    tenant = Treby.Tenants.get_tenant!(request.tenant_id)
    admins = Treby.Accounts.list_users(request.tenant_id) |> Enum.filter(&(&1.role == "admin"))

    Enum.each(admins, fn admin ->
      email =
        Swoosh.Email.new()
        |> Swoosh.Email.to(admin.email)
        |> Swoosh.Email.from({"Treby", "noreply@treby.app"})
        |> Swoosh.Email.subject("Data & Privacy erasure requested for #{tenant.name}")
        |> Swoosh.Email.text_body(
          "Tenant #{tenant.slug} has a pending erasure. Grace until #{get_in(request.metadata, ["grace_until"])}. Cancel at Settings → Data & Privacy."
        )

      Treby.Mailer.deliver(email)
    end)
  rescue
    _ -> :ok
  end

  defp maybe_notify_erasure_request(_), do: :ok

  defp enqueue_worker(%DataPrivacyRequest{type: "export"} = request) do
    %{data_privacy_request_id: request.id}
    |> Treby.Workers.DataPrivacyExportWorker.new()
    |> Oban.insert()
  end

  defp enqueue_worker(%DataPrivacyRequest{type: "erasure"} = request) do
    %{data_privacy_request_id: request.id}
    |> Treby.Workers.DataPrivacyErasureWorker.new()
    |> Oban.insert()
  end

  def get_request!(tenant_id, id) do
    Repo.get_by!(DataPrivacyRequest, id: id, tenant_id: tenant_id)
  end

  def get_request(tenant_id, id) do
    Repo.get_by(DataPrivacyRequest, id: id, tenant_id: tenant_id)
  end

  def list_requests(tenant_id, opts \\ []) do
    requester_id = Keyword.get(opts, :requester_id)
    type = Keyword.get(opts, :type)
    status = Keyword.get(opts, :status)

    DataPrivacyRequest
    |> where([r], r.tenant_id == ^tenant_id)
    |> maybe_where(:requester_id, requester_id)
    |> maybe_where(:type, type)
    |> maybe_where(:status, status)
    |> order_by([r], desc: r.inserted_at)
    |> Repo.all()
  end

  defp maybe_where(query, _field, nil), do: query

  defp maybe_where(query, field, value) do
    where(query, [r], field(r, ^field) == ^value)
  end

  def transition(%DataPrivacyRequest{} = request, new_status, attrs \\ %{}) do
    request
    |> DataPrivacyRequest.changeset(Map.merge(%{status: new_status}, attrs))
    |> Repo.update()
  end

  def cancel(%DataPrivacyRequest{status: status} = _request)
      when status not in ["pending", "processing"] do
    {:error, :not_cancellable}
  end

  def cancel(%DataPrivacyRequest{} = request) do
    case transition(request, "cancelled", %{
           metadata:
             Map.put(
               request.metadata || %{},
               "cancelled_at",
               DateTime.utc_now() |> DateTime.to_iso8601()
             )
         }) do
      {:ok, cancelled} ->
        Treby.Audit.log_event(
          "data_privacy.erasure_cancelled",
          "data_privacy_request",
          cancelled.id,
          %{
            tenant_id: cancelled.tenant_id,
            actor_id: cancelled.requester_id,
            metadata: %{type: cancelled.type, scope: cancelled.scope}
          }
        )

        {:ok, cancelled}

      error ->
        error
    end
  end

  def expire_ready do
    now = DateTime.utc_now()

    from(r in DataPrivacyRequest, where: r.status == "ready" and r.expires_at <= ^now)
    |> Repo.all()
    |> Enum.each(fn request ->
      if request.s3_key do
        try do
          Treby.Uploads.delete_file(request.tenant_id, request.s3_key)
        rescue
          _ -> :ok
        end
      end

      {:ok, expired} = transition(request, "expired")

      Treby.Audit.log_event("data_privacy.export_expired", "data_privacy_request", expired.id, %{
        tenant_id: expired.tenant_id,
        actor_id: expired.requester_id,
        metadata: %{type: "export", scope: expired.scope}
      })
    end)
  end
end
