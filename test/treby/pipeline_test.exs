defmodule Treby.PipelineTest do
  use Treby.DataCase, async: true

  alias Treby.Pipeline
  alias Treby.Pipeline.Analytics
  alias Treby.Pipeline.Stages
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

  describe "analytics tenant scoping parity" do
    test "tenant-scoped delegates match unscoped for explicit pipeline", %{
      tenant: tenant,
      job: job
    } do
      pipeline_id = job.pipeline_id || Pipeline.default_pipeline_id(tenant.id)

      assert Pipeline.pipeline_counts_per_stage(tenant.id, pipeline_id) ==
               Pipeline.pipeline_counts_per_stage(pipeline_id)

      assert Pipeline.average_time_to_hire(tenant.id, pipeline_id) ==
               Pipeline.average_time_to_hire(pipeline_id)

      assert Pipeline.stage_conversion_rates(tenant.id, pipeline_id) ==
               Pipeline.stage_conversion_rates(pipeline_id)
    end

    test "facade delegates to submodules", %{tenant: tenant} do
      assert Pipeline.list_pipelines(tenant.id) ==
               Stages.list_pipelines(tenant.id)

      assert Pipeline.pipeline_counts_per_stage(nil) ==
               Analytics.pipeline_counts_per_stage(nil)
    end

    test "grouped stage counts match independent per-stage counts", %{
      tenant: tenant,
      job: job
    } do
      import Ecto.Query

      pipeline_id = job.pipeline_id || Pipeline.default_pipeline_id(tenant.id)

      counts = Pipeline.pipeline_counts_per_stage(pipeline_id)
      assert Enum.map(counts, & &1.count) |> Enum.sum() == 1

      for %{stage: stage, count: count} <- counts do
        expected =
          Treby.Pipeline.Application
          |> where([a], a.pipeline_stage_id == ^stage.id)
          |> Treby.Repo.aggregate(:count)

        assert count == expected
      end
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

  describe "uuid v7 ordering" do
    test "same-timestamp applications order by descending id", %{tenant: tenant, job: job} do
      import Ecto.Query

      {:ok, first_candidate} = insert_candidate(tenant.id)
      {:ok, second_candidate} = insert_candidate(tenant.id)
      {:ok, _first} = insert_application(tenant.id, job.id, first_candidate.id)
      {:ok, second} = insert_application(tenant.id, job.id, second_candidate.id)

      now = DateTime.utc_now() |> DateTime.truncate(:second)

      Treby.Pipeline.Application
      |> where([a], a.job_id == ^job.id)
      |> Repo.update_all(set: [inserted_at: now])

      assert [%{id: newest_id} | _] = Pipeline.list_applications_for_job(job.id)
      assert newest_id == second.id
    end
  end

  describe "notification failure observability" do
    test "failed notification keeps the move and is logged + metered", %{app: app} do
      import Ecto.Query
      import ExUnit.CaptureLog

      app = Repo.reload(app) |> Repo.preload(:pipeline_stage)

      new_stage =
        Repo.one!(
          from s in Treby.Pipeline.PipelineStage,
            where:
              s.pipeline_id == ^app.pipeline_stage.pipeline_id and
                s.id != ^app.pipeline_stage_id,
            limit: 1
        )

      test_pid = self()
      handler_id = "test-notify-failed-#{System.unique_integer([:positive])}"

      :telemetry.attach(
        handler_id,
        [:treby, :pipeline, :notify_failed],
        fn event, measurements, metadata, _ ->
          send(test_pid, {:notify_failed, event, measurements, metadata})
        end,
        nil
      )

      try do
        log =
          capture_log(fn ->
            assert {:ok, moved} =
                     Pipeline.move_application(app, new_stage.id,
                       notify_fn: fn _, _ -> raise "mail boom" end
                     )

            assert moved.pipeline_stage_id == new_stage.id
          end)

        assert log =~ "notify_stage_change failed"

        assert_received {:notify_failed, [:treby, :pipeline, :notify_failed], %{count: 1},
                         %{application_id: app_id, error: error}}

        assert app_id == app.id
        assert error =~ "mail boom"
      after
        :telemetry.detach(handler_id)
      end
    end
  end

  describe "race-safe pipeline detach" do
    test "concurrent detaches give each job its own clone, shared pipeline untouched", %{
      tenant: tenant,
      job: job,
      app: app
    } do
      import Ecto.Query
      alias Ecto.Adapters.SQL.Sandbox

      {:ok, job2} = insert_job(tenant.id)
      {:ok, candidate2} = insert_candidate(tenant.id)
      {:ok, app2} = insert_application(tenant.id, job2.id, candidate2.id)

      original_id = Treby.Pipeline.default_pipeline_id(tenant.id)

      stage_ids = fn pipeline_id ->
        from(s in Treby.Pipeline.PipelineStage, where: s.pipeline_id == ^pipeline_id)
        |> Repo.all()
        |> MapSet.new(& &1.id)
      end

      original_stages = stage_ids.(original_id)

      test_pid = self()

      results =
        [job, job2]
        |> Task.async_stream(
          fn j ->
            Sandbox.allow(Repo, test_pid, self())
            Pipeline.detach_job_pipeline(Repo.reload!(j))
          end,
          max_concurrency: 2,
          timeout: 30_000
        )
        |> Enum.map(fn {:ok, result} -> result end)

      assert [{:ok, updated1, p1}, {:ok, updated2, p2}] = results

      # Exactly one clone: whichever detach ran second found the pipeline
      # no longer shared and correctly became a no-op
      assert [clone] = Enum.reject([p1, p2], &(&1.id == original_id))
      assert Enum.find([updated1, updated2], &(&1.pipeline_id == clone.id))
      assert Enum.find([updated1, updated2], &(&1.pipeline_id == original_id))

      # Shared pipeline untouched; each application's stage follows its job
      assert stage_ids.(original_id) == original_stages

      job_apps = %{updated1.id => app, updated2.id => app2}

      for updated <- [updated1, updated2] do
        expected_stages =
          if updated.pipeline_id == original_id, do: original_stages, else: stage_ids.(clone.id)

        assert Repo.reload!(job_apps[updated.id]).pipeline_stage_id in expected_stages
      end
    end
  end

  describe "pipeline name uniqueness and rename" do
    test "rejects duplicate pipeline names within a tenant", %{tenant: tenant} do
      assert {:ok, _} =
               Pipeline.create_pipeline(%{name: "Engineering", tenant_id: tenant.id})

      assert {:error, changeset} =
               Pipeline.create_pipeline(%{name: "Engineering", tenant_id: tenant.id})

      assert errors_on(changeset).name == ["has already been taken"]
    end

    test "allows the same name in different tenants", %{tenant: tenant} do
      {:ok, other_tenant} =
        Repo.insert(%Treby.Tenants.Tenant{
          name: "Other Tenant",
          slug: "other-#{System.unique_integer([:positive])}"
        })

      assert {:ok, _} = Pipeline.create_pipeline(%{name: "Shared", tenant_id: tenant.id})

      assert {:ok, _} =
               Pipeline.create_pipeline(%{name: "Shared", tenant_id: other_tenant.id})
    end

    test "rename to a taken name fails, rename to a free name works", %{tenant: tenant} do
      {:ok, first} = Pipeline.create_pipeline(%{name: "One", tenant_id: tenant.id})
      {:ok, second} = Pipeline.create_pipeline(%{name: "Two", tenant_id: tenant.id})

      assert {:error, changeset} = Pipeline.update_pipeline(second, %{name: "One"})
      assert errors_on(changeset).name == ["has already been taken"]

      assert {:ok, renamed} = Pipeline.update_pipeline(second, %{name: "Two v2"})
      assert renamed.name == "Two v2"

      assert {:ok, same} = Pipeline.update_pipeline(first, %{name: "One"})
      assert same.name == "One"
    end

    test "duplicate_pipeline generates unique copy names", %{tenant: tenant} do
      {:ok, pipeline} = Pipeline.create_pipeline(%{name: "Base", tenant_id: tenant.id})
      {:ok, copy1} = Pipeline.duplicate_pipeline(pipeline)
      {:ok, copy2} = Pipeline.duplicate_pipeline(pipeline)

      assert copy1.name == "Base (Copy)"
      assert copy2.name == "Base (Copy 2)"
    end

    test "repeated detaches from the same source get unique names", %{tenant: tenant} do
      {:ok, job1} = insert_job(tenant.id)
      {:ok, job2} = insert_job(tenant.id)
      {:ok, _job3} = insert_job(tenant.id)

      assert {:ok, _, clone1} = Pipeline.detach_job_pipeline(job1)
      assert {:ok, _, clone2} = Pipeline.detach_job_pipeline(job2)

      assert clone1.id != clone2.id
      assert clone1.name != clone2.name
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
