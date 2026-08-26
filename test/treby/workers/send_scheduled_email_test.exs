defmodule Treby.Workers.SendScheduledEmailTest do
  use Treby.DataCase, async: false

  import Oban.Testing

  alias Treby.{Tenants, Accounts, Candidates, EmailThreads, EmailQueue, Repo}
  alias Treby.Candidates.Candidate
  alias Treby.EmailQueue.ScheduledEmail
  alias Treby.Workers.SendScheduledEmail

  defmodule FailingAdapter do
    @behaviour Swoosh.Adapter

    @impl true
    def deliver(_email, _config), do: {:error, :simulated_delivery_failure}

    @impl true
    def validate_config(_config), do: :ok
  end

  defp setup_tenant do
    {:ok, tenant} =
      Tenants.create_tenant(%{
        name: "Test Corp",
        slug: "test-#{System.unique_integer([:positive])}"
      })

    {:ok, _user} =
      tenant
      |> Ecto.build_assoc(:users)
      |> Accounts.User.changeset(%{
        email: "test-#{System.unique_integer([:positive])}@test.com",
        password: "password123",
        name: "Test User",
        role: "admin"
      })
      |> Repo.insert()

    {tenant, nil}
  end

  defp create_scheduled(tenant, overrides \\ %{}) do
    now = DateTime.utc_now()
    later = DateTime.add(now, 3600, :second)

    {:ok, scheduled} =
      EmailQueue.create_scheduled_email(
        Map.merge(
          %{
            tenant_id: tenant.id,
            scheduled_at: later,
            to_address: "candidate@example.com",
            from_address: "recruiter@example.com",
            subject: "Test Subject",
            html_body: "<p>Test body</p>",
            email_type: "compose"
          },
          overrides
        )
      )

    scheduled
  end

  describe "backoff/1" do
    test "returns exponential backoff matching the design" do
      assert SendScheduledEmail.backoff(%Oban.Job{attempt: 2}) == 60
      assert SendScheduledEmail.backoff(%Oban.Job{attempt: 3}) == 240
      assert SendScheduledEmail.backoff(%Oban.Job{attempt: 4}) == 900
      assert SendScheduledEmail.backoff(%Oban.Job{attempt: 5}) == 3600
      assert SendScheduledEmail.backoff(%Oban.Job{attempt: 6}) == 3600
    end
  end

  describe "perform/1" do
    test "sends email and updates status to sent" do
      {tenant, _user} = setup_tenant()
      scheduled = create_scheduled(tenant)

      {:ok, _updated} = perform_job(SendScheduledEmail, %{scheduled_email_id: scheduled.id}, [])

      updated = EmailQueue.get_scheduled_email!(scheduled.id)
      assert updated.status == "sent"
    end

    test "marks the linked thread message as sent after delivery" do
      {tenant, _user} = setup_tenant()

      {:ok, candidate} =
        tenant
        |> Ecto.build_assoc(:candidates)
        |> Candidate.changeset(%{
          name: "Linked Candidate",
          email: "linked@example.com"
        })
        |> Repo.insert()

      {:ok, message} =
        EmailThreads.create_outbound_email(%{
          candidate_id: candidate.id,
          tenant_id: tenant.id,
          from_address: "recruiter@example.com",
          to_address: "linked@example.com",
          subject: "Linked message",
          body: "body",
          email_type: "compose",
          schedule: %{scheduled_at: DateTime.add(DateTime.utc_now(), 3600, :second)}
        })

      scheduled = create_scheduled(tenant)

      {:ok, _} =
        scheduled
        |> ScheduledEmail.changeset(%{email_message_id: message.id})
        |> Repo.update()

      {:ok, _} = perform_job(SendScheduledEmail, %{scheduled_email_id: scheduled.id}, [])

      message = Repo.reload!(message)
      assert message.status == "sent"
    end

    test "discards if email already sent" do
      {tenant, _user} = setup_tenant()
      scheduled = create_scheduled(tenant)
      EmailQueue.update_status(scheduled, "sent")

      {:discard, _reason} =
        perform_job(SendScheduledEmail, %{scheduled_email_id: scheduled.id}, [])
    end

    test "discards if email not found" do
      {:discard, _reason} =
        perform_job(
          SendScheduledEmail,
          %{scheduled_email_id: "00000000-0000-0000-0000-000000000000"},
          []
        )
    end

    test "discards if email is cancelled" do
      {tenant, _user} = setup_tenant()
      scheduled = create_scheduled(tenant)
      Repo.update!(ScheduledEmail.changeset(scheduled, %{status: "cancelled"}))

      {:discard, _reason} =
        perform_job(SendScheduledEmail, %{scheduled_email_id: scheduled.id}, [])
    end
  end

  describe "perform/1 with delivery failure" do
    setup do
      Application.put_env(:treby, Treby.Mailer, adapter: FailingAdapter)

      on_exit(fn ->
        Application.put_env(:treby, Treby.Mailer, adapter: Swoosh.Adapters.Test)
      end)

      :ok
    end

    test "keeps email scheduled on transient failure so retry can happen" do
      {tenant, _user} = setup_tenant()
      scheduled = create_scheduled(tenant)

      {:error, _reason} =
        perform_job(SendScheduledEmail, %{scheduled_email_id: scheduled.id},
          attempt: 1,
          max_attempts: 5
        )

      updated = EmailQueue.get_scheduled_email!(scheduled.id)
      assert updated.status == "scheduled"
      assert updated.retry_count == 1
      refute is_nil(updated.error_reason)
    end

    test "marks email as failed on the final attempt" do
      {tenant, _user} = setup_tenant()
      scheduled = create_scheduled(tenant)

      {:error, _reason} =
        perform_job(SendScheduledEmail, %{scheduled_email_id: scheduled.id},
          attempt: 5,
          max_attempts: 5
        )

      updated = EmailQueue.get_scheduled_email!(scheduled.id)
      assert updated.status == "failed"
      assert updated.retry_count == 1
      refute is_nil(updated.failed_at)
      refute is_nil(updated.error_reason)
    end
  end
end
