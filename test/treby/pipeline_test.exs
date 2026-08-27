defmodule Treby.PipelineTest do
  use Treby.DataCase, async: true

  alias Treby.Pipeline
  alias Treby.Repo

  setup do
    {:ok, tenant} = insert_tenant()
    {:ok, examiner1} = insert_user(tenant.id)
    {:ok, examiner2} = insert_user(tenant.id)
    {:ok, job} = insert_job(tenant.id)
    {:ok, candidate} = insert_candidate(tenant.id)
    {:ok, app} = insert_application(tenant.id, job.id, candidate.id)

    {:ok,
     tenant: tenant,
     examiner1: examiner1,
     examiner2: examiner2,
     job: job,
     candidate: candidate,
     app: app}
  end

  describe "current_state/1" do
    test "non-interview stage with no blockers", %{app: app} do
      state = Pipeline.current_state(app)
      assert state.blocked? == false
      assert state.blockers == []
      assert Enum.any?(state.next_actions, &(&1.kind == :advance))
    end

    test "interview stage with a scheduled (not completed) interview", %{
      tenant: tenant,
      app: app,
      examiner1: examiner1,
      examiner2: examiner2
    } do
      move_to_interview_stage(app)

      {:ok, _event} = create_interview(app, tenant.id, [examiner1.id, examiner2.id], "scheduled")

      state = Pipeline.current_state(Repo.reload(app) |> Repo.preload(:pipeline_stage))
      assert state.blocked? == true
      assert Enum.any?(state.blockers, &(&1.kind == :interview_not_completed))
    end

    test "interview stage completed with a missing scorecard names the pending examiner", %{
      tenant: tenant,
      app: app,
      examiner1: examiner1,
      examiner2: examiner2
    } do
      move_to_interview_stage(app)

      {:ok, event} = create_interview(app, tenant.id, [examiner1.id, examiner2.id], "completed")

      submit_scorecard(event.id, examiner1.id, tenant.id)

      state = Pipeline.current_state(Repo.reload(app) |> Repo.preload(:pipeline_stage))
      assert state.blocked? == true

      pending = Enum.filter(state.blockers, &(&1.kind == :scorecard_pending))
      assert length(pending) == 1
      assert pending |> hd() |> Map.fetch!(:assignee) |> Map.fetch!(:user_id) == examiner2.id
    end

    test "interview stage fully resolved reports not blocked", %{
      tenant: tenant,
      app: app,
      examiner1: examiner1,
      examiner2: examiner2
    } do
      move_to_interview_stage(app)

      {:ok, event} = create_interview(app, tenant.id, [examiner1.id, examiner2.id], "completed")

      submit_scorecard(event.id, examiner1.id, tenant.id)
      submit_scorecard(event.id, examiner2.id, tenant.id)

      state = Pipeline.current_state(Repo.reload(app) |> Repo.preload(:pipeline_stage))
      assert state.blocked? == false
      assert state.blockers == []
    end

    test "reports scorecard progress counts", %{
      tenant: tenant,
      app: app,
      examiner1: examiner1,
      examiner2: examiner2
    } do
      move_to_interview_stage(app)

      {:ok, event} = create_interview(app, tenant.id, [examiner1.id, examiner2.id], "completed")

      submit_scorecard(event.id, examiner1.id, tenant.id)

      state = Pipeline.current_state(Repo.reload(app) |> Repo.preload(:pipeline_stage))
      assert state.progress.scorecards == %{completed: 1, total: 2}
      assert state.progress.interviews.completed == 1
    end
  end

  describe "ready_to_advance?/1 and interview_completed?/1" do
    test "non-interview stage is ready to advance", %{app: app} do
      assert Pipeline.ready_to_advance?(app)
      assert Pipeline.interview_completed?(app)
    end

    test "interview with a scheduled event is not ready to advance", %{
      tenant: tenant,
      app: app,
      examiner1: examiner1
    } do
      move_to_interview_stage(app)
      {:ok, _event} = create_interview(app, tenant.id, [examiner1.id], "scheduled")

      app = Repo.reload(app) |> Repo.preload(:pipeline_stage)
      refute Pipeline.interview_completed?(app)
      refute Pipeline.ready_to_advance?(app)
    end

    test "interview completed with all scorecards is ready to advance", %{
      tenant: tenant,
      app: app,
      examiner1: examiner1
    } do
      move_to_interview_stage(app)
      {:ok, event} = create_interview(app, tenant.id, [examiner1.id], "completed")
      submit_scorecard(event.id, examiner1.id, tenant.id)

      app = Repo.reload(app) |> Repo.preload(:pipeline_stage)
      assert Pipeline.interview_completed?(app)
      assert Pipeline.ready_to_advance?(app)
    end

    test "interview completed but missing a scorecard is not ready to advance", %{
      tenant: tenant,
      app: app,
      examiner1: examiner1,
      examiner2: examiner2
    } do
      move_to_interview_stage(app)
      {:ok, event} = create_interview(app, tenant.id, [examiner1.id, examiner2.id], "completed")
      submit_scorecard(event.id, examiner1.id, tenant.id)

      app = Repo.reload(app) |> Repo.preload(:pipeline_stage)
      assert Pipeline.interview_completed?(app)
      refute Pipeline.ready_to_advance?(app)
    end
  end

  describe "complete_interview/2" do
    test "sets the interview status to completed without moving the application", %{
      tenant: tenant,
      app: app,
      examiner1: examiner1
    } do
      move_to_interview_stage(app)
      {:ok, event} = create_interview(app, tenant.id, [examiner1.id], "scheduled")
      stage_before = Repo.reload(app).pipeline_stage_id

      assert event.status == "scheduled"

      {:ok, completed} = Treby.Interviews.complete_interview(event, nil)
      assert completed.status == "completed"

      assert Repo.reload(app).pipeline_stage_id == stage_before
    end
  end

  defp insert_tenant do
    tenant =
      Repo.insert!(%Treby.Tenants.Tenant{
        name: "Test Tenant",
        slug: "test-#{System.unique_integer([:positive])}"
      })

    Treby.Pipeline.create_default_pipeline_stages(tenant)

    {:ok, tenant}
  end

  defp insert_user(tenant_id) do
    Repo.insert!(%Treby.Accounts.User{
      name: "Test User",
      email: "test-#{System.unique_integer([:positive])}@example.com",
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
      Repo.one(
        from s in Treby.Pipeline.PipelineStage,
          where: s.pipeline_id == ^pipeline_id and s.stage_type == "new",
          limit: 1
      )

    {:ok, app} =
      %Treby.Pipeline.Application{}
      |> Ecto.Changeset.change(%{
        job_id: job_id,
        candidate_id: candidate_id,
        pipeline_stage_id:
          (stage ||
             Repo.one(
               from s in Treby.Pipeline.PipelineStage,
                 where: s.pipeline_id == ^pipeline_id,
                 limit: 1
             )).id,
        tenant_id: job.tenant_id,
        applied_at: DateTime.utc_now() |> DateTime.truncate(:second)
      })
      |> Repo.insert()

    {:ok, app}
  end

  defp move_to_interview_stage(app) do
    job = Repo.get!(Treby.Jobs.Job, app.job_id)
    pipeline_id = job.pipeline_id || Treby.Pipeline.default_pipeline_id(job.tenant_id)

    stage =
      Repo.one(
        from s in Treby.Pipeline.PipelineStage,
          where: s.pipeline_id == ^pipeline_id and s.stage_type == "interview"
      )

    if stage do
      Pipeline.move_application(app, stage.id, skip_notification: true)
    end

    stage
  end

  defp create_interview(app, _tenant_id, examiner_ids, status) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    # Build event directly to control status without notifications
    {:ok, event} =
      %Treby.Interviews.InterviewEvent{}
      |> Ecto.Changeset.change(%{
        start_at_utc: DateTime.add(now, 3600),
        end_at_utc: DateTime.add(now, 3600) |> DateTime.add(1800, :second),
        duration_minutes: 30,
        application_id: app.id,
        tenant_id: app.tenant_id,
        status: status
      })
      |> Repo.insert()

    Enum.each(examiner_ids, fn user_id ->
      %Treby.Interviews.EventExaminer{}
      |> Ecto.Changeset.change(%{
        interview_event_id: event.id,
        user_id: user_id
      })
      |> Repo.insert!()
    end)

    {:ok, event}
  end

  defp submit_scorecard(event_id, interviewer_id, tenant_id) do
    {:ok, _} =
      Treby.Scorecards.submit_scorecard(event_id, interviewer_id, %{
        "scores" => %{"skill" => 4},
        "recommendation" => "hire",
        "notes" => "ok",
        "tenant_id" => tenant_id
      })
  end
end
