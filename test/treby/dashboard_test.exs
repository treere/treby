defmodule Treby.DashboardTest do
  use Treby.DataCase, async: true

  alias Treby.Dashboard
  alias Treby.Interviews.InterviewEvent
  alias Treby.Interviews.EventExaminer

  setup do
    {:ok, tenant} = insert_tenant()
    {:ok, user} = insert_user(tenant.id)
    {:ok, other_user} = insert_user(tenant.id)
    %{tenant: tenant, user: user, other_user: other_user}
  end

  describe "my_actions/2 pending_scorecards" do
    test "returns events where the user is an examiner and their scorecard is missing", %{
      tenant: tenant,
      user: user,
      other_user: other_user
    } do
      app = setup_interview_application(tenant, [user.id, other_user.id])

      result = Dashboard.my_actions(tenant.id, user.id)

      assert [pending] = result.pending_scorecards
      assert pending.event_id != nil
      assert pending.candidate_name == app.candidate.name
      assert pending.job_title == app.job.title
      assert pending.start_at != nil
    end

    test "does not include scorecards the user already submitted", %{
      tenant: tenant,
      user: user,
      other_user: other_user
    } do
      app = setup_interview_application(tenant, [user.id, other_user.id])

      event = Repo.one!(from e in InterviewEvent, where: e.application_id == ^app.id)

      {:ok, _scorecard} =
        Treby.Scorecards.submit_scorecard(event.id, user.id, %{
          "scores" => %{"Communication" => 4},
          "recommendation" => "hire",
          "notes" => "Great",
          "tenant_id" => tenant.id
        })

      result = Dashboard.my_actions(tenant.id, user.id)

      assert result.pending_scorecards == []
    end

    test "does not include another examiner's missing scorecard as the user's action", %{
      tenant: tenant,
      user: user,
      other_user: other_user
    } do
      app = setup_interview_application(tenant, [user.id, other_user.id])

      event = Repo.one!(from e in InterviewEvent, where: e.application_id == ^app.id)

      {:ok, _scorecard} =
        Treby.Scorecards.submit_scorecard(event.id, user.id, %{
          "scores" => %{"Communication" => 4},
          "recommendation" => "hire",
          "notes" => "Great",
          "tenant_id" => tenant.id
        })

      # other_user still missing, but that is not the user's pending action
      result = Dashboard.my_actions(tenant.id, user.id)
      assert result.pending_scorecards == []
    end

    test "returns empty list when no pending scorecards", %{tenant: tenant, user: user} do
      result = Dashboard.my_actions(tenant.id, user.id)
      assert result.pending_scorecards == []
    end
  end

  describe "my_actions/2 waiting_on_others" do
    test "lists application blocked by another examiner's missing scorecard", %{
      tenant: tenant,
      user: user,
      other_user: other_user
    } do
      app = setup_interview_application(tenant, [user.id, other_user.id])

      # Complete the interview, user submits, other_user still missing
      event = Repo.one!(from e in InterviewEvent, where: e.application_id == ^app.id)

      {:ok, _} = Treby.Interviews.complete_interview(event)

      {:ok, _scorecard} =
        Treby.Scorecards.submit_scorecard(event.id, user.id, %{
          "scores" => %{"Communication" => 4},
          "recommendation" => "hire",
          "notes" => "Great",
          "tenant_id" => tenant.id
        })

      result = Dashboard.my_actions(tenant.id, user.id)

      assert [waiting] = result.waiting_on_others
      assert waiting.candidate_name == app.candidate.name
      assert waiting.job_title == app.job.title
      assert Enum.any?(waiting.blockers, &(&1 =~ "scorecard missing"))
    end

    test "does not list application when only the user's own scorecard is missing", %{
      tenant: tenant,
      user: user,
      other_user: other_user
    } do
      app = setup_interview_application(tenant, [user.id, other_user.id])

      event = Repo.one!(from e in InterviewEvent, where: e.application_id == ^app.id)
      {:ok, _} = Treby.Interviews.complete_interview(event)

      # other_user submitted, user has not
      {:ok, _scorecard} =
        Treby.Scorecards.submit_scorecard(event.id, other_user.id, %{
          "scores" => %{"Communication" => 4},
          "recommendation" => "hire",
          "notes" => "Great",
          "tenant_id" => tenant.id
        })

      result = Dashboard.my_actions(tenant.id, user.id)

      # user's own pending scorecard is an action for them, not "waiting on others"
      assert result.waiting_on_others == []
    end

    test "lists application with incomplete interview", %{
      tenant: tenant,
      user: user,
      other_user: other_user
    } do
      app = setup_interview_application(tenant, [user.id, other_user.id])

      result = Dashboard.my_actions(tenant.id, user.id)

      assert [waiting] = result.waiting_on_others
      assert waiting.candidate_name == app.candidate.name
      assert Enum.any?(waiting.blockers, &(&1 =~ "not yet completed"))
    end

    test "does not list non-interview applications", %{tenant: tenant, user: user} do
      {:ok, job} = insert_job(tenant.id)
      {:ok, candidate} = insert_candidate(tenant.id)
      {:ok, _app} = insert_application(tenant.id, job.id, candidate.id)

      result = Dashboard.my_actions(tenant.id, user.id)

      assert result.waiting_on_others == []
      assert result.pending_scorecards == []
      refute Enum.any?(result.waiting_on_others, &(&1.candidate_name == candidate.name))
    end
  end

  defp setup_interview_application(tenant, examiner_ids) do
    {:ok, job} = insert_job(tenant.id)
    {:ok, candidate} = insert_candidate(tenant.id)

    stage =
      Repo.one!(
        from s in Treby.Pipeline.PipelineStage,
          where: s.stage_type == "interview" and s.pipeline_id == ^job.pipeline_id
      )

    {:ok, app} =
      Repo.insert(%Treby.Pipeline.Application{
        job_id: job.id,
        candidate_id: candidate.id,
        pipeline_stage_id: stage.id,
        tenant_id: tenant.id,
        applied_at: DateTime.utc_now() |> DateTime.truncate(:second)
      })

    now = DateTime.utc_now() |> DateTime.truncate(:second)

    {:ok, event} =
      Repo.insert(%InterviewEvent{
        start_at_utc: DateTime.add(now, 1, :day),
        end_at_utc: DateTime.add(now, 1, :day) |> DateTime.add(1800, :second),
        duration_minutes: 30,
        status: "scheduled",
        application_id: app.id,
        tenant_id: tenant.id
      })

    Enum.each(examiner_ids, fn uid ->
      Repo.insert!(%EventExaminer{interview_event_id: event.id, user_id: uid})
    end)

    Repo.preload(app, [:candidate, :job])
  end

  defp insert_tenant do
    tenant =
      Repo.insert!(%Treby.Tenants.Tenant{
        name: "Dashboard Test Tenant",
        slug: "dash-ctx-#{System.unique_integer([:positive])}"
      })

    Treby.Pipeline.create_default_pipeline_stages(tenant)
    {:ok, tenant}
  end

  defp insert_user(tenant_id) do
    Repo.insert!(%Treby.Accounts.User{
      name: "Test User",
      email: "user-#{System.unique_integer([:positive])}@example.com",
      password_hash: Bcrypt.hash_pwd_salt("password123456"),
      tenant_id: tenant_id
    })
    |> then(&{:ok, &1})
  end

  defp insert_job(tenant_id) do
    pipeline_id = Treby.Pipeline.default_pipeline_id(tenant_id)

    {:ok, job} =
      %Treby.Jobs.Job{}
      |> Ecto.Changeset.change(%{
        title: "Test Job",
        description: "A test job posting",
        tenant_id: tenant_id,
        pipeline_id: pipeline_id
      })
      |> Repo.insert()

    {:ok, job}
  end

  defp insert_candidate(tenant_id) do
    {:ok, candidate} =
      %Treby.Candidates.Candidate{}
      |> Ecto.Changeset.change(%{
        name: "Test Candidate",
        email: "candidate-#{System.unique_integer([:positive])}@example.com",
        tenant_id: tenant_id
      })
      |> Repo.insert()

    {:ok, candidate}
  end

  defp insert_application(_tenant_id, job_id, candidate_id) do
    job = Repo.get!(Treby.Jobs.Job, job_id)
    pipeline_id = job.pipeline_id || Treby.Pipeline.default_pipeline_id(job.tenant_id)

    stage =
      Repo.one!(
        from s in Treby.Pipeline.PipelineStage,
          where: s.pipeline_id == ^pipeline_id,
          order_by: s.position,
          limit: 1
      )

    {:ok, app} =
      %Treby.Pipeline.Application{}
      |> Ecto.Changeset.change(%{
        job_id: job_id,
        candidate_id: candidate_id,
        pipeline_stage_id: stage.id,
        tenant_id: job.tenant_id,
        applied_at: DateTime.utc_now() |> DateTime.truncate(:second)
      })
      |> Repo.insert()

    {:ok, app}
  end
end
