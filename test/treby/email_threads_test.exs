defmodule Treby.EmailThreadsTest do
  use Treby.DataCase, async: true

  alias Treby.{Tenants, Repo}
  alias Treby.Accounts.User
  alias Treby.Candidates.Candidate
  alias Treby.EmailThreads
  alias Treby.EmailQueue.ScheduledEmail

  defp setup_tenant do
    {:ok, tenant} =
      Tenants.create_tenant(%{
        name: "Test Corp",
        slug: "test-#{System.unique_integer([:positive])}"
      })

    {:ok, user} =
      tenant
      |> Ecto.build_assoc(:users)
      |> User.changeset(%{
        email: "test-#{System.unique_integer([:positive])}@test.com",
        password: "password123",
        name: "Test User",
        role: "admin"
      })
      |> Repo.insert()

    {:ok, candidate} =
      tenant
      |> Ecto.build_assoc(:candidates)
      |> Candidate.changeset(%{
        name: "Jane Candidate",
        email: "jane@example.com"
      })
      |> Repo.insert()

    {tenant, user, candidate}
  end

  describe "create_outbound_email/1" do
    test "sends immediately when no schedule is provided" do
      {tenant, user, candidate} = setup_tenant()

      {:ok, message} =
        EmailThreads.create_outbound_email(%{
          subject: "Hello",
          body: "Hi there",
          from_address: user.email,
          candidate_id: candidate.id,
          tenant_id: tenant.id,
          created_by_id: user.id
        })

      assert message.status == "sent"
      assert message.direction == "outbound"
      assert message.to_address == "jane@example.com"
    end

    test "creates a scheduled email when schedule is provided" do
      {tenant, user, candidate} = setup_tenant()
      scheduled_at = DateTime.truncate(DateTime.add(DateTime.utc_now(), 7200, :second), :second)

      {:ok, message} =
        EmailThreads.create_outbound_email(%{
          subject: "Hello",
          body: "Hi there",
          from_address: user.email,
          candidate_id: candidate.id,
          tenant_id: tenant.id,
          created_by_id: user.id,
          schedule: %{scheduled_at: scheduled_at, jitter_minutes: 0}
        })

      assert message.status == "scheduled"
      assert message.scheduled_at == scheduled_at

      queued = Repo.get_by!(ScheduledEmail, thread_id: message.thread_id)
      assert queued.email_type == "compose"
      assert queued.email_message_id == message.id
    end
  end

  describe "send_reply/5" do
    test "sends immediately when no schedule is provided" do
      {tenant, user, candidate} = setup_tenant()

      {:ok, outbound} =
        EmailThreads.create_outbound_email(%{
          subject: "Hello",
          body: "Hi there",
          from_address: user.email,
          candidate_id: candidate.id,
          tenant_id: tenant.id,
          created_by_id: user.id
        })

      {:ok, reply} =
        EmailThreads.send_reply(outbound.thread_id, user.email, "Replying", tenant.id)

      assert reply.status == "sent"
      assert reply.direction == "outbound"
    end

    test "creates a scheduled reply when schedule is provided" do
      {tenant, user, candidate} = setup_tenant()

      {:ok, outbound} =
        EmailThreads.create_outbound_email(%{
          subject: "Hello",
          body: "Hi there",
          from_address: user.email,
          candidate_id: candidate.id,
          tenant_id: tenant.id,
          created_by_id: user.id
        })

      scheduled_at = DateTime.truncate(DateTime.add(DateTime.utc_now(), 3600, :second), :second)

      {:ok, reply} =
        EmailThreads.send_reply(outbound.thread_id, user.email, "Replying", tenant.id,
          schedule: %{scheduled_at: scheduled_at, jitter_minutes: 5}
        )

      assert reply.status == "scheduled"

      queued = Repo.get_by!(ScheduledEmail, thread_id: reply.thread_id)
      assert queued.email_type == "reply"
      assert queued.jitter_minutes == 5
      assert queued.email_message_id == reply.id
    end
  end

  describe "create_inbound_email/1" do
    test "creates an inbound message and updates thread last_message_at" do
      {tenant, _user, candidate} = setup_tenant()

      {:ok, message} =
        EmailThreads.create_inbound_email(%{
          subject: "Interested",
          from_address: "jane@example.com",
          to_address: "recruiter@example.com",
          body: "Hello there",
          candidate_id: candidate.id,
          tenant_id: tenant.id
        })

      assert message.direction == "inbound"
      assert message.status == "sent"

      threads = EmailThreads.list_threads_for_candidate(candidate.id)
      assert length(threads) == 1
    end
  end

  describe "list_threads_for_candidate/1" do
    test "groups messages into a single thread by subject" do
      {tenant, user, candidate} = setup_tenant()

      {:ok, first} =
        EmailThreads.create_outbound_email(%{
          subject: "Interview",
          body: "Round 1",
          from_address: user.email,
          candidate_id: candidate.id,
          tenant_id: tenant.id,
          created_by_id: user.id
        })

      {:ok, _second} =
        EmailThreads.create_outbound_email(%{
          subject: "Interview",
          body: "Round 2",
          from_address: user.email,
          candidate_id: candidate.id,
          tenant_id: tenant.id,
          created_by_id: user.id
        })

      threads = EmailThreads.list_threads_for_candidate(candidate.id)
      assert length(threads) == 1
      [thread] = threads
      assert thread.id == first.thread_id
      assert length(thread.messages) == 2
    end
  end
end
