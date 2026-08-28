defmodule Treby.BulkOperationsTest do
  use Treby.DataCase, async: true

  import Ecto.Query

  alias Treby.{Tenants, Repo}
  alias Treby.Accounts.User
  alias Treby.Candidates.Candidate
  alias Treby.ScheduledMessages.ScheduledMessage
  alias Treby.BulkOperations
  alias Treby.Pipeline

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

    {:ok, job} =
      Treby.Jobs.create_job(%{
        tenant_id: tenant.id,
        title: "Engineer",
        description: "Backend engineer"
      })

    {:ok, pipeline} =
      Pipeline.create_pipeline(%{name: "Default", tenant_id: tenant.id, is_default: true})

    {:ok, stage} =
      Pipeline.create_pipeline_stage(%{
        name: "Applied",
        position: 1,
        pipeline_id: pipeline.id,
        tenant_id: tenant.id,
        stage_type: "applied"
      })

    {tenant, user, job, stage}
  end

  defp create_candidate(tenant, email) do
    {:ok, candidate} =
      tenant
      |> Ecto.build_assoc(:candidates)
      |> Candidate.changeset(%{name: "Cand #{System.unique_integer([:positive])}", email: email})
      |> Repo.insert()

    candidate
  end

  defp create_application(tenant, job, stage, candidate) do
    {:ok, application} =
      Pipeline.create_application(%{
        tenant_id: tenant.id,
        job_id: job.id,
        candidate_id: candidate.id,
        pipeline_stage_id: stage.id,
        applied_at: DateTime.utc_now()
      })

    application
  end

  defp strip_email(candidate) do
    from(c in Candidate, where: c.id == ^candidate.id)
    |> Repo.update_all(set: [email: ""])

    Repo.get!(Candidate, candidate.id)
  end

  describe "bulk_send_message/3 (immediate)" do
    test "posts messages to each candidate's conversation" do
      {tenant, _user, job, stage} = setup_tenant()

      with_email = create_candidate(tenant, "one@example.com")
      no_email = create_candidate(tenant, "two@example.com") |> strip_email()

      app1 = create_application(tenant, job, stage, with_email)
      app2 = create_application(tenant, job, stage, no_email)

      {:ok, result} =
        BulkOperations.bulk_send_message([app1.id, app2.id], "Hi {candidate_name}", tenant.id)

      assert result.sent == 2
      assert result.failed == 0
      assert result.skipped == 0

      conversations = Treby.CandidatePortal.list_conversations_for_application(app1.id, tenant.id)
      assert length(conversations) == 1
      conversation = List.first(conversations)
      messages = Treby.Repo.preload(conversation, :messages).messages
      assert length(messages) == 1
      assert List.first(messages).body =~ with_email.name
    end

    test "returns sent count matching successful postings" do
      {tenant, _user, job, stage} = setup_tenant()
      c1 = create_candidate(tenant, "a@example.com")
      c2 = create_candidate(tenant, "b@example.com")

      a1 = create_application(tenant, job, stage, c1)
      a2 = create_application(tenant, job, stage, c2)

      {:ok, result} = BulkOperations.bulk_send_message([a1.id, a2.id], "Hi", tenant.id)

      assert result.sent == 2
      assert result.failed == 0
      assert result.skipped == 0
    end
  end

  describe "bulk_send_message/3 (scheduled)" do
    test "schedules messages for each candidate" do
      {tenant, _user, job, stage} = setup_tenant()

      with_email = create_candidate(tenant, "one@example.com")
      no_email = create_candidate(tenant, "two@example.com") |> strip_email()

      app1 = create_application(tenant, job, stage, with_email)
      app2 = create_application(tenant, job, stage, no_email)

      scheduled_at = DateTime.add(DateTime.utc_now(), 3600, :second)

      {:ok, result} =
        BulkOperations.bulk_send_message(
          [app1.id, app2.id],
          "Hi {candidate_name}",
          tenant.id,
          schedule: %{scheduled_at: scheduled_at, jitter_minutes: 0}
        )

      assert result.sent == 2
      assert result.failed == 0
      assert result.skipped == 0

      queued =
        from(s in ScheduledMessage, where: s.tenant_id == ^tenant.id, select: s.body)
        |> Repo.all()

      assert length(queued) == 2
      assert Enum.all?(queued, &(&1 =~ "Hi"))
    end

    test "applies jitter from schedule options" do
      {tenant, _user, job, stage} = setup_tenant()
      c1 = create_candidate(tenant, "a@example.com")
      a1 = create_application(tenant, job, stage, c1)

      scheduled_at = DateTime.add(DateTime.utc_now(), 7200, :second)

      {:ok, result} =
        BulkOperations.bulk_send_message(
          [a1.id],
          "Hi",
          tenant.id,
          schedule: %{scheduled_at: scheduled_at, jitter_minutes: 10}
        )

      assert result.sent == 1

      conversation =
        Treby.CandidatePortal.list_conversations_for_application(a1.id, tenant.id)
        |> List.first()

      queued = Repo.get_by!(ScheduledMessage, conversation_id: conversation.id)
      assert queued.message_type == "text"
      assert queued.metadata["bulk"] == true
    end
  end
end
