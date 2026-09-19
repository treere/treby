defmodule Treby.Workers.DataPrivacyErasureWorker do
  use Oban.Worker, queue: :default, max_attempts: 3

  import Ecto.Query, warn: false
  alias Treby.Accounts.User
  alias Treby.Candidates.Candidate
  alias Treby.DataPrivacy.DataPrivacyRequest
  alias Treby.DataPrivacy.Requests
  alias Treby.Memberships.Membership
  alias Treby.Repo

  @backoff_by_attempt %{2 => 120, 3 => 600}

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"data_privacy_request_id" => id}}) do
    request = Repo.get(DataPrivacyRequest, id)

    case request do
      nil ->
        {:discard, "data_privacy_request not found"}

      %{status: "cancelled"} ->
        {:discard, "cancelled"}

      %{status: status} when status not in ["pending", "processing"] ->
        {:discard, "already #{status}"}

      request ->
        do_erasure(request)
    end
  end

  def perform(%Oban.Job{args: args}) do
    id = args["data_privacy_request_id"] || args[:data_privacy_request_id]

    if id,
      do: perform(%Oban.Job{args: %{"data_privacy_request_id" => id}}),
      else: {:discard, "missing data_privacy_request_id"}
  end

  @impl Oban.Worker
  def backoff(%Oban.Job{attempt: attempt}), do: Map.get(@backoff_by_attempt, attempt, 600)

  defp do_erasure(request) do
    grace_until =
      get_in(request.metadata || %{}, ["grace_until"]) ||
        get_in(request.metadata || %{}, [:grace_until])

    if grace_until do
      {:ok, grace_dt, _} = DateTime.from_iso8601(to_string(grace_until))

      if DateTime.compare(DateTime.utc_now(), grace_dt) == :lt do
        # Re-enqueue after grace
        delay = DateTime.diff(grace_dt, DateTime.utc_now(), :second) + 5

        %{data_privacy_request_id: request.id}
        |> __MODULE__.new(schedule_in: delay)
        |> Oban.insert()

        {:ok, _} = Requests.transition(request, "processing")
        :ok
      else
        execute_erasure(request)
      end
    else
      execute_erasure(request)
    end
  end

  defp execute_erasure(request) do
    {:ok, _} = Requests.transition(request, "processing")

    try do
      case request.scope do
        "user" -> erase_user(request)
        "tenant" -> erase_tenant(request)
      end

      {:ok, completed} =
        Requests.transition(request, "completed", %{completed_at: DateTime.utc_now()})

      Treby.Audit.log_event(
        "data_privacy.erasure_completed",
        "data_privacy_request",
        completed.id,
        %{
          tenant_id: completed.tenant_id,
          actor_id: completed.requester_id,
          metadata: %{type: "erasure", scope: completed.scope}
        }
      )

      maybe_clear_pending_flag(request)
      send_erasure_completed_email(completed)

      :ok
    rescue
      e ->
        {:ok, _} = Requests.transition(request, "failed", %{error: Exception.message(e)})
        {:error, Exception.message(e)}
    end
  end

  defp send_erasure_completed_email(request) do
    case Repo.get(User, request.requester_id) do
      nil ->
        :ok

      user ->
        email =
          Swoosh.Email.new()
          |> Swoosh.Email.to(user.email)
          |> Swoosh.Email.from({"Treby", "noreply@treby.app"})
          |> Swoosh.Email.subject("Your erasure request completed")
          |> Swoosh.Email.text_body(
            "Erasure #{request.scope} completed for tenant #{request.tenant_id}."
          )

        Treby.Mailer.deliver(email)
        :ok
    end
  rescue
    _ -> :ok
  end

  defp erase_user(request) do
    user = Repo.get!(User, request.requester_id)

    # Guard last admin
    if last_admin?(request.tenant_id, user.id) do
      raise "Cannot erase last admin"
    end

    Treby.DataPrivacy.Anonymizer.anonymize_user(user)
    Treby.DataPrivacy.Anonymizer.anonymize_audit_metadata(request.tenant_id, [user.id])

    # Remove memberships
    from(m in Membership,
      where: m.user_id == ^user.id and m.tenant_id == ^request.tenant_id
    )
    |> Repo.delete_all()
  end

  defp erase_tenant(request) do
    tenant_id = request.tenant_id

    # Collect ids for audit scrub
    candidate_ids =
      Repo.all(from c in Candidate, where: c.tenant_id == ^tenant_id, select: c.id)

    user_ids =
      Repo.all(
        from u in User,
          join: m in Membership,
          on: m.user_id == u.id,
          where: m.tenant_id == ^tenant_id,
          select: u.id
      )

    Treby.DataPrivacy.Anonymizer.anonymize_tenant_candidates(tenant_id)
    Treby.DataPrivacy.Anonymizer.anonymize_tenant_users(tenant_id)
    Treby.DataPrivacy.Anonymizer.anonymize_audit_metadata(tenant_id, candidate_ids ++ user_ids)

    # Delete webhook subscriptions, AI conversations if exist
    try do
      from(w in Treby.Webhooks.WebhookSubscription, where: w.tenant_id == ^tenant_id)
      |> Repo.delete_all()
    rescue
      _ -> :ok
    end

    try do
      from(a in Treby.AI.Conversation, where: a.tenant_id == ^tenant_id) |> Repo.delete_all()
    rescue
      _ -> :ok
    end

    # Mark tenant as erased
    tenant = Treby.Tenants.get_tenant!(tenant_id)

    settings =
      Map.merge(tenant.settings || %{}, %{
        "data_privacy_erased_at" => DateTime.utc_now() |> DateTime.to_iso8601(),
        "data_privacy_pending_erasure" => nil
      })

    tenant |> Ecto.Changeset.change(%{settings: settings}) |> Repo.update()
  end

  defp last_admin?(tenant_id, user_id) do
    admin_count =
      Repo.aggregate(
        from(m in Membership,
          where: m.tenant_id == ^tenant_id and m.role == "admin"
        ),
        :count,
        :id
      )

    is_admin =
      Repo.exists?(
        from m in Membership,
          where: m.tenant_id == ^tenant_id and m.user_id == ^user_id and m.role == "admin"
      )

    admin_count == 1 and is_admin
  end

  defp maybe_clear_pending_flag(request) do
    if request.scope == "tenant" do
      tenant = Treby.Tenants.get_tenant!(request.tenant_id)
      settings = Map.put(tenant.settings || %{}, "data_privacy_pending_erasure", nil)
      tenant |> Ecto.Changeset.change(%{settings: settings}) |> Repo.update()
    end
  end
end
