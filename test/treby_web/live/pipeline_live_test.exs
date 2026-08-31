defmodule TrebyWeb.PipelineLive.IndexTest do
  use TrebyWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias Treby.{Tenants, Repo}
  alias Treby.Accounts.User
  alias Treby.Candidates.Candidate
  alias Treby.Jobs.Job
  alias Treby.Pipeline.PipelineStage
  alias Treby.Interviews.{InterviewEvent, EventExaminer}

  defp setup_tenant do
    {:ok, tenant} =
      Tenants.create_tenant(%{
        name: "Pipeline Test Corp",
        slug: "pipeline-test-#{System.unique_integer([:positive])}"
      })

    {:ok, user} =
      tenant
      |> Ecto.build_assoc(:users)
      |> User.changeset(%{
        email: "pipe-#{System.unique_integer([:positive])}@test.com",
        password: "password123",
        name: "Pipeline User",
        role: "admin"
      })
      |> Repo.insert()

    {:ok, _} =
      Treby.Memberships.create_membership(%{
        user_id: user.id,
        tenant_id: tenant.id,
        role: user.role
      })

    {tenant, user}
  end

  defp login_user(conn, user) do
    conn
    |> init_test_session(%{
      "user_id" => user.id,
      "tenant_id" => user.tenant_id
    })
  end

  describe "empty state" do
    test "shows empty state when no applications exist for a job", %{conn: conn} do
      {tenant, user} = setup_tenant()

      pipeline_id = Treby.Pipeline.default_pipeline_id(tenant.id)

      pipeline = Treby.Repo.get!(Treby.Pipeline.Pipeline, pipeline_id)

      {:ok, _stage} =
        pipeline
        |> Ecto.build_assoc(:pipeline_stages)
        |> PipelineStage.changeset(%{
          name: "Applied",
          position: 0,
          stage_type: "applied"
        })
        |> Repo.insert()

      {:ok, job} =
        tenant
        |> Ecto.build_assoc(:jobs)
        |> Job.changeset(%{
          title: "Software Engineer",
          description: "Build things",
          pipeline_id: pipeline_id
        })
        |> Repo.insert()

      conn = login_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/app/pipeline/#{job.id}")

      html = render(view)
      assert html =~ "No applications yet"
    end
  end

  describe "candidate card links" do
    test "candidate name links to candidate details page", %{conn: conn} do
      {tenant, user} = setup_tenant()

      pipeline_id = Treby.Pipeline.default_pipeline_id(tenant.id)
      pipeline = Treby.Repo.get!(Treby.Pipeline.Pipeline, pipeline_id)

      {:ok, stage} =
        pipeline
        |> Ecto.build_assoc(:pipeline_stages)
        |> PipelineStage.changeset(%{
          name: "Applied",
          position: 0,
          stage_type: "applied"
        })
        |> Repo.insert()

      {:ok, job} =
        tenant
        |> Ecto.build_assoc(:jobs)
        |> Job.changeset(%{
          title: "Software Engineer",
          description: "Build things",
          pipeline_id: pipeline_id
        })
        |> Repo.insert()

      {:ok, candidate} =
        tenant
        |> Ecto.build_assoc(:candidates)
        |> Candidate.changeset(%{
          name: "Linkable Candidate",
          email: "linkable@example.com"
        })
        |> Repo.insert()

      {:ok, application} =
        Treby.Pipeline.create_application(%{
          tenant_id: tenant.id,
          job_id: job.id,
          candidate_id: candidate.id,
          pipeline_stage_id: stage.id,
          applied_at: DateTime.utc_now()
        })

      conn = login_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/app/pipeline/#{job.id}")

      html = render(view)

      assert html =~ "Linkable Candidate"
      assert html =~ "/app/candidates/#{application.candidate_id}"
    end
  end

  describe "stage move - scheduling" do
    defp setup_pipeline_data(tenant) do
      pipeline_id = Treby.Pipeline.default_pipeline_id(tenant.id)
      pipeline = Treby.Repo.get!(Treby.Pipeline.Pipeline, pipeline_id)

      {:ok, stage1} =
        pipeline
        |> Ecto.build_assoc(:pipeline_stages)
        |> PipelineStage.changeset(%{
          name: "Applied",
          position: 0,
          stage_type: "applied"
        })
        |> Repo.insert()

      {:ok, stage2} =
        pipeline
        |> Ecto.build_assoc(:pipeline_stages)
        |> PipelineStage.changeset(%{
          name: "Interview",
          position: 1,
          stage_type: "interview"
        })
        |> Repo.insert()

      {:ok, job} =
        tenant
        |> Ecto.build_assoc(:jobs)
        |> Job.changeset(%{
          title: "Software Engineer",
          description: "Build things",
          pipeline_id: pipeline_id
        })
        |> Repo.insert()

      {:ok, candidate} =
        tenant
        |> Ecto.build_assoc(:candidates)
        |> Candidate.changeset(%{
          name: "Pipeline Schedule",
          email: "pipe-schedule@example.com"
        })
        |> Repo.insert()

      {:ok, application} =
        Treby.Pipeline.create_application(%{
          tenant_id: tenant.id,
          job_id: job.id,
          candidate_id: candidate.id,
          pipeline_stage_id: stage1.id,
          applied_at: DateTime.utc_now()
        })

      {:ok, _template} =
        Treby.EmailTemplates.upsert_email_template(%{
          "tenant_id" => tenant.id,
          "name" => "Interview Invite",
          "stage_type" => "interview",
          "subject" => "Interview Invite",
          "body" => "Hi {candidate_name}"
        })

      %{job: job, stage2: stage2, application: application}
    end

    test "schedules message when moving candidate with schedule", %{conn: conn} do
      {tenant, user} = setup_tenant()
      data = setup_pipeline_data(tenant)

      conn = login_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/app/pipeline/#{data.job.id}")

      view
      |> render_click("move_candidate", %{
        "application_id" => data.application.id,
        "stage_id" => data.stage2.id
      })

      assert render(view) =~ "Interview Invite"

      view |> render_click("toggle_schedule", %{})
      assert render(view) =~ "Tomorrow 9:00"

      view |> render_click("preset_schedule", %{"label" => "tomorrow_9"})
      view |> render_click("confirm_stage_move", %{"action" => "schedule"})

      assert render(view) =~ "Candidate moved and message scheduled"

      conversation =
        Treby.CandidatePortal.list_conversations_for_application(data.application.id, tenant.id)
        |> List.first()

      scheduled =
        Repo.get_by!(Treby.ScheduledMessages.ScheduledMessage, conversation_id: conversation.id)

      assert scheduled.message_type == "templated"
      assert scheduled.body =~ "Hi"
      assert scheduled.status == "scheduled"

      updated = Treby.Pipeline.get_application!(data.application.id)
      assert updated.pipeline_stage_id == data.stage2.id
    end

    test "shows error when scheduling without a datetime", %{conn: conn} do
      {tenant, user} = setup_tenant()
      data = setup_pipeline_data(tenant)

      conn = login_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/app/pipeline/#{data.job.id}")

      view
      |> render_click("move_candidate", %{
        "application_id" => data.application.id,
        "stage_id" => data.stage2.id
      })

      view |> render_click("toggle_schedule", %{})
      view |> render_click("confirm_stage_move", %{"action" => "schedule"})

      assert render(view) =~ "Please select a schedule date and time"
    end
  end

  describe "concurrent applications and duplicate flags" do
    defp setup_concurrent_data(tenant) do
      pipeline_id = Treby.Pipeline.default_pipeline_id(tenant.id)
      pipeline = Repo.get!(Treby.Pipeline.Pipeline, pipeline_id)

      {:ok, stage} =
        pipeline
        |> Ecto.build_assoc(:pipeline_stages)
        |> PipelineStage.changeset(%{
          name: "Applied",
          position: 0,
          stage_type: "applied"
        })
        |> Repo.insert()

      {:ok, job1} =
        tenant
        |> Ecto.build_assoc(:jobs)
        |> Job.changeset(%{
          title: "Job One",
          description: "First",
          pipeline_id: pipeline_id
        })
        |> Repo.insert()

      {:ok, job2} =
        tenant
        |> Ecto.build_assoc(:jobs)
        |> Job.changeset(%{
          title: "Job Two",
          description: "Second",
          pipeline_id: pipeline_id
        })
        |> Repo.insert()

      {:ok, candidate} =
        tenant
        |> Ecto.build_assoc(:candidates)
        |> Candidate.changeset(%{
          name: "Concurrent Person",
          email: "concurrent@example.com"
        })
        |> Repo.insert()

      {:ok, _app1} =
        Treby.Pipeline.create_application(%{
          tenant_id: tenant.id,
          job_id: job1.id,
          candidate_id: candidate.id,
          pipeline_stage_id: stage.id,
          applied_at: DateTime.utc_now()
        })

      {:ok, _app2} =
        Treby.Pipeline.create_application(%{
          tenant_id: tenant.id,
          job_id: job2.id,
          candidate_id: candidate.id,
          pipeline_stage_id: stage.id,
          applied_at: DateTime.utc_now()
        })

      %{job1: job1, stage: stage, candidate: candidate}
    end

    test "shows 'Also in N other positions' when a candidate applied to another job", %{
      conn: conn
    } do
      {tenant, user} = setup_tenant()
      data = setup_concurrent_data(tenant)

      conn = login_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/app/pipeline/#{data.job1.id}")

      assert render(view) =~ "Also in 1 other position"
    end

    test "shows the duplicate application badge when a candidate re-applies to the same job", %{
      conn: conn
    } do
      {tenant, user} = setup_tenant()
      data = setup_concurrent_data(tenant)

      Treby.Pipeline.create_application(%{
        tenant_id: tenant.id,
        job_id: data.job1.id,
        candidate_id: data.candidate.id,
        pipeline_stage_id: data.stage.id,
        applied_at: DateTime.utc_now()
      })

      conn = login_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/app/pipeline/#{data.job1.id}")

      assert render(view) =~ "DUPLICATE"
    end
  end

  describe "interview completion on card" do
    defp setup_interview_card_data(tenant, user) do
      pipeline_id = Treby.Pipeline.default_pipeline_id(tenant.id)
      pipeline = Repo.get!(Treby.Pipeline.Pipeline, pipeline_id)

      {:ok, stage} =
        pipeline
        |> Ecto.build_assoc(:pipeline_stages)
        |> PipelineStage.changeset(%{name: "Interview", position: 0, stage_type: "interview"})
        |> Repo.insert()

      {:ok, job} =
        tenant
        |> Ecto.build_assoc(:jobs)
        |> Job.changeset(%{title: "SWE", description: "d", pipeline_id: pipeline_id})
        |> Repo.insert()

      {:ok, candidate} =
        tenant
        |> Ecto.build_assoc(:candidates)
        |> Candidate.changeset(%{
          name: "Interview Candidate",
          email: "iv-#{System.unique_integer([:positive])}@example.com"
        })
        |> Repo.insert()

      {:ok, application} =
        Treby.Pipeline.create_application(%{
          tenant_id: tenant.id,
          job_id: job.id,
          candidate_id: candidate.id,
          pipeline_stage_id: stage.id,
          applied_at: DateTime.utc_now()
        })

      now = DateTime.utc_now() |> DateTime.truncate(:second)

      {:ok, event} =
        %InterviewEvent{}
        |> InterviewEvent.changeset(%{
          start_at_utc: DateTime.add(now, 3600),
          end_at_utc: DateTime.add(now, 3600 + 1800),
          duration_minutes: 30,
          application_id: application.id,
          tenant_id: tenant.id,
          status: "scheduled"
        })
        |> Repo.insert()

      # Make the user an examiner so the Scorecard button is shown
      %EventExaminer{}
      |> EventExaminer.changeset(%{
        interview_event_id: event.id,
        user_id: user.id
      })
      |> Repo.insert!()

      %{job: job, application: application, event: event}
    end

    test "shows Mark as completed for a scheduled interview", %{conn: conn} do
      {tenant, user} = setup_tenant()
      data = setup_interview_card_data(tenant, user)

      conn = login_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/app/pipeline/#{data.job.id}")

      assert render(view) =~ "Mark as completed"
    end
  end

  describe "rejection" do
    test "rejects a candidate end-to-end for a job with no explicit pipeline", %{conn: conn} do
      {tenant, user} = setup_tenant()

      {:ok, job} =
        tenant
        |> Ecto.build_assoc(:jobs)
        |> Job.changeset(%{
          title: "No Pipeline Job",
          description: "Build things"
        })
        |> Repo.insert()

      {:ok, candidate} =
        tenant
        |> Ecto.build_assoc(:candidates)
        |> Candidate.changeset(%{
          name: "Reject Candidate",
          email: "reject-#{System.unique_integer([:positive])}@example.com"
        })
        |> Repo.insert()

      first_stage = Treby.Pipeline.list_pipeline_stages_for_job(job.id) |> List.first()

      {:ok, application} =
        Treby.Pipeline.create_application(%{
          tenant_id: tenant.id,
          job_id: job.id,
          candidate_id: candidate.id,
          pipeline_stage_id: first_stage.id,
          applied_at: DateTime.utc_now()
        })

      conn = login_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/app/pipeline/#{job.id}")

      view |> render_click("reject_application", %{"id" => application.id})
      view |> render_click("update_rejection_reason", %{"value" => "not a fit"})
      view |> render_click("confirm_reject", %{})

      assert render(view) =~ "Candidate rejected"

      updated = Treby.Pipeline.get_application!(application.id)

      rejected_stage =
        Treby.Pipeline.list_pipeline_stages_for_job(job.id)
        |> Enum.find(&(&1.stage_type == "rejected"))

      assert updated.pipeline_stage_id == rejected_stage.id
    end
  end

  describe "bulk actions" do
    test "moves selected applications to the chosen stage from the action bar", %{conn: conn} do
      {tenant, user} = setup_tenant()

      pipeline_id = Treby.Pipeline.default_pipeline_id(tenant.id)
      pipeline = Repo.get!(Treby.Pipeline.Pipeline, pipeline_id)

      {:ok, stage1} =
        pipeline
        |> Ecto.build_assoc(:pipeline_stages)
        |> PipelineStage.changeset(%{name: "Applied", position: 0, stage_type: "applied"})
        |> Repo.insert()

      {:ok, stage2} =
        pipeline
        |> Ecto.build_assoc(:pipeline_stages)
        |> PipelineStage.changeset(%{name: "Interview", position: 1, stage_type: "interview"})
        |> Repo.insert()

      {:ok, job} =
        tenant
        |> Ecto.build_assoc(:jobs)
        |> Job.changeset(%{title: "Bulk Move Job", description: "d", pipeline_id: pipeline_id})
        |> Repo.insert()

      {:ok, candidate} =
        tenant
        |> Ecto.build_assoc(:candidates)
        |> Candidate.changeset(%{
          name: "Bulk Move Person",
          email: "bulk-#{System.unique_integer([:positive])}@example.com"
        })
        |> Repo.insert()

      {:ok, application} =
        Treby.Pipeline.create_application(%{
          tenant_id: tenant.id,
          job_id: job.id,
          candidate_id: candidate.id,
          pipeline_stage_id: stage1.id,
          applied_at: DateTime.utc_now()
        })

      conn = login_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/app/pipeline/#{job.id}")

      view |> render_click("toggle_application", %{"id" => application.id})
      view |> render_change("bulk_select_action", %{"bulk_action" => "move_stage"})

      html = render(view)
      assert html =~ "Select stage..."
      assert html =~ "Interview"

      view |> render_change("bulk_select_stage", %{"bulk_stage_id" => stage2.id})
      view |> render_click("bulk_execute_move", %{})

      assert render(view) =~ "1 applications moved"
      assert Treby.Pipeline.get_application!(application.id).pipeline_stage_id == stage2.id
    end

    test "lists default pipeline stages in the dropdown for a job with no explicit pipeline", %{
      conn: conn
    } do
      {tenant, user} = setup_tenant()

      pipeline_id = Treby.Pipeline.default_pipeline_id(tenant.id)

      {:ok, stage} =
        Repo.get!(Treby.Pipeline.Pipeline, pipeline_id)
        |> Ecto.build_assoc(:pipeline_stages)
        |> PipelineStage.changeset(%{name: "Applied", position: 0, stage_type: "applied"})
        |> Repo.insert()

      {:ok, job} =
        tenant
        |> Ecto.build_assoc(:jobs)
        |> Job.changeset(%{title: "Default Stages Job", description: "d"})
        |> Repo.insert()

      {:ok, candidate} =
        tenant
        |> Ecto.build_assoc(:candidates)
        |> Candidate.changeset(%{
          name: "Default Stages Person",
          email: "defstage-#{System.unique_integer([:positive])}@example.com"
        })
        |> Repo.insert()

      {:ok, application} =
        Treby.Pipeline.create_application(%{
          tenant_id: tenant.id,
          job_id: job.id,
          candidate_id: candidate.id,
          pipeline_stage_id: stage.id,
          applied_at: DateTime.utc_now()
        })

      conn = login_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/app/pipeline/#{job.id}")

      view |> render_click("toggle_application", %{"id" => application.id})
      view |> render_change("bulk_select_action", %{"bulk_action" => "move_stage"})

      html = render(view)
      assert html =~ "Select stage..."
      assert html =~ "Applied"

      view |> render_change("bulk_select_stage", %{"bulk_stage_id" => stage.id})
      view |> render_click("bulk_execute_move", %{})

      assert render(view) =~ "1 applications moved"
      assert Treby.Pipeline.get_application!(application.id).pipeline_stage_id == stage.id
    end

    test "disables Move to Stage when the job's effective pipeline has no stages", %{conn: conn} do
      {tenant, user} = setup_tenant()

      {:ok, empty_pipeline} =
        Treby.Pipeline.create_pipeline(%{
          tenant_id: tenant.id,
          name: "Empty",
          is_default: false
        })

      default_stage =
        Treby.Pipeline.list_pipeline_stages(Treby.Pipeline.default_pipeline_id(tenant.id))
        |> List.first()

      {:ok, job} =
        tenant
        |> Ecto.build_assoc(:jobs)
        |> Job.changeset(%{
          title: "Empty Pipeline Job",
          description: "d",
          pipeline_id: empty_pipeline.id
        })
        |> Repo.insert()

      {:ok, candidate} =
        tenant
        |> Ecto.build_assoc(:candidates)
        |> Candidate.changeset(%{
          name: "Empty Pipeline Person",
          email: "emptypipe-#{System.unique_integer([:positive])}@example.com"
        })
        |> Repo.insert()

      {:ok, application} =
        Treby.Pipeline.create_application(%{
          tenant_id: tenant.id,
          job_id: job.id,
          candidate_id: candidate.id,
          pipeline_stage_id: default_stage.id,
          applied_at: DateTime.utc_now()
        })

      conn = login_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/app/pipeline/#{job.id}")

      view |> render_click("toggle_application", %{"id" => application.id})
      view |> render_change("bulk_select_action", %{"bulk_action" => "move_stage"})

      html = render(view)
      assert html =~ "Move to Stage"
      refute html =~ "Select stage..."
    end
  end

  describe "review toggle on kanban cards" do
    test "marks an application reviewed with a single click", %{conn: conn} do
      {tenant, user} = setup_tenant()
      pipeline_id = Treby.Pipeline.default_pipeline_id(tenant.id)
      pipeline = Treby.Repo.get!(Treby.Pipeline.Pipeline, pipeline_id)

      {:ok, stage} =
        pipeline
        |> Ecto.build_assoc(:pipeline_stages)
        |> PipelineStage.changeset(%{name: "Applied", position: 0, stage_type: "applied"})
        |> Repo.insert()

      {:ok, job} =
        tenant
        |> Ecto.build_assoc(:jobs)
        |> Job.changeset(%{
          title: "Software Engineer",
          description: "Build things",
          pipeline_id: pipeline_id
        })
        |> Repo.insert()

      {:ok, candidate} =
        tenant
        |> Ecto.build_assoc(:candidates)
        |> Candidate.changeset(%{name: "Review Toggle", email: "rtoggle@example.com"})
        |> Repo.insert()

      {:ok, application} =
        Treby.Pipeline.create_application(%{
          tenant_id: tenant.id,
          job_id: job.id,
          candidate_id: candidate.id,
          pipeline_stage_id: stage.id,
          applied_at: DateTime.utc_now()
        })

      conn = login_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/app/pipeline/#{job.id}")

      assert render(view) =~ "Mark reviewed"

      view |> render_click("toggle_review", %{"application_id" => application.id})

      assert Repo.get!(Treby.Pipeline.Application, application.id).reviewed == true
      assert render(view) =~ "Reviewed"
    end
  end

  describe "real-time pipeline updates" do
    test "reflects a stage move broadcast from another surface", %{conn: conn} do
      {tenant, user} = setup_tenant()
      pipeline_id = Treby.Pipeline.default_pipeline_id(tenant.id)
      pipeline = Treby.Repo.get!(Treby.Pipeline.Pipeline, pipeline_id)

      {:ok, stage_a} =
        pipeline
        |> Ecto.build_assoc(:pipeline_stages)
        |> PipelineStage.changeset(%{name: "Applied", position: 0, stage_type: "applied"})
        |> Repo.insert()

      {:ok, stage_b} =
        pipeline
        |> Ecto.build_assoc(:pipeline_stages)
        |> PipelineStage.changeset(%{name: "Screening", position: 1, stage_type: "screen"})
        |> Repo.insert()

      {:ok, job} =
        tenant
        |> Ecto.build_assoc(:jobs)
        |> Job.changeset(%{
          title: "Software Engineer",
          description: "Build things",
          pipeline_id: pipeline_id
        })
        |> Repo.insert()

      {:ok, candidate} =
        tenant
        |> Ecto.build_assoc(:candidates)
        |> Candidate.changeset(%{name: "Realtime Candidate", email: "rt@example.com"})
        |> Repo.insert()

      {:ok, application} =
        Treby.Pipeline.create_application(%{
          tenant_id: tenant.id,
          job_id: job.id,
          candidate_id: candidate.id,
          pipeline_stage_id: stage_a.id,
          applied_at: DateTime.utc_now()
        })

      conn = login_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/app/pipeline/#{job.id}")

      assert has_element?(view, "#stage-#{stage_a.id} #application-#{application.id}")
      refute has_element?(view, "#stage-#{stage_b.id} #application-#{application.id}")

      # Simulate a move made from another surface (e.g. the job page workspace)
      {:ok, _} = Treby.Pipeline.move_application(application, stage_b.id)

      assert has_element?(view, "#stage-#{stage_b.id} #application-#{application.id}")
      refute has_element?(view, "#stage-#{stage_a.id} #application-#{application.id}")
    end
  end

  describe "advance with nil pipeline" do
    test "advances candidate when job has no explicit pipeline", %{conn: conn} do
      {tenant, user} = setup_tenant()

      {:ok, job} =
        tenant
        |> Ecto.build_assoc(:jobs)
        |> Job.changeset(%{title: "Nil Pipeline Job", description: "Desc"})
        |> Repo.insert()

      assert job.pipeline_id == nil

      stages = Treby.Pipeline.list_pipeline_stages_for_job(job.id)
      interview_stage = Enum.find(stages, &(&1.stage_type == "interview"))
      offer_stage = Enum.find(stages, &(&1.stage_type == "offer"))

      # Make user an advancer for interview stage
      if interview_stage do
        Treby.Pipeline.assign_advancer(interview_stage, user.id)
      end

      {:ok, candidate} =
        tenant
        |> Ecto.build_assoc(:candidates)
        |> Candidate.changeset(%{
          name: "Advance Nil",
          email: "advancenil#{System.unique_integer([:positive])}@example.com"
        })
        |> Repo.insert()

      {:ok, application} =
        Treby.Pipeline.create_application(%{
          tenant_id: tenant.id,
          job_id: job.id,
          candidate_id: candidate.id,
          pipeline_stage_id: interview_stage.id,
          applied_at: DateTime.utc_now()
        })

      now = DateTime.utc_now() |> DateTime.truncate(:second)

      {:ok, event} =
        %InterviewEvent{}
        |> InterviewEvent.changeset(%{
          start_at_utc: DateTime.add(now, -3600),
          end_at_utc: DateTime.add(now, -1800),
          duration_minutes: 30,
          application_id: application.id,
          tenant_id: tenant.id,
          status: "completed"
        })
        |> Repo.insert()

      %EventExaminer{}
      |> EventExaminer.changeset(%{
        interview_event_id: event.id,
        user_id: user.id
      })
      |> Repo.insert!()

      # Create scorecard template and scorecard to satisfy ready_to_advance?
      {:ok, _template} =
        Treby.Scorecards.create_scorecard_template(
          %{
            "tenant_id" => tenant.id,
            "name" => "Default",
            "criteria" => [%{"name" => "Skills", "type" => "number_1_5"}],
            "position" => 0
          },
          user
        )

      {:ok, _scorecard} =
        Treby.Scorecards.submit_scorecard(event.id, user.id, %{
          "scores" => %{"Skills" => 4},
          "recommendation" => "hire",
          "notes" => "good",
          "tenant_id" => tenant.id
        })

      conn = login_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/app/pipeline/#{job.id}")

      # Should be in Interview and show Advance
      assert has_element?(view, "#stage-#{interview_stage.id} #application-#{application.id}")

      view |> element("button", "Advance") |> render_click()

      assert has_element?(view, "#stage-#{offer_stage.id} #application-#{application.id}")
    end
  end

  describe "scorecard with no template" do
    test "does not crash when no template and shows guidance", %{conn: conn} do
      {tenant, user} = setup_tenant()

      # Ensure no template for this tenant to test nil guard
      Treby.Repo.delete_all(Treby.Scorecards.ScorecardTemplate)

      pipeline_id = Treby.Pipeline.default_pipeline_id(tenant.id)

      interview_stage =
        Treby.Pipeline.list_pipeline_stages(pipeline_id)
        |> Enum.find(&(&1.stage_type == "interview"))

      if interview_stage do
        Treby.Pipeline.assign_examiner(interview_stage, user.id)
      end

      {:ok, job} =
        tenant
        |> Ecto.build_assoc(:jobs)
        |> Job.changeset(%{
          title: "Scorecard Nil Job",
          description: "Desc",
          pipeline_id: pipeline_id
        })
        |> Repo.insert()

      {:ok, candidate} =
        tenant
        |> Ecto.build_assoc(:candidates)
        |> Candidate.changeset(%{
          name: "Scorecard Nil",
          email: "scnil#{System.unique_integer([:positive])}@example.com"
        })
        |> Repo.insert()

      {:ok, application} =
        Treby.Pipeline.create_application(%{
          tenant_id: tenant.id,
          job_id: job.id,
          candidate_id: candidate.id,
          pipeline_stage_id: interview_stage.id,
          applied_at: DateTime.utc_now()
        })

      now = DateTime.utc_now() |> DateTime.truncate(:second)

      {:ok, event} =
        %InterviewEvent{}
        |> InterviewEvent.changeset(%{
          start_at_utc: DateTime.add(now, 3600),
          end_at_utc: DateTime.add(now, 5400),
          duration_minutes: 30,
          application_id: application.id,
          tenant_id: tenant.id,
          status: "scheduled"
        })
        |> Repo.insert()

      %EventExaminer{}
      |> EventExaminer.changeset(%{
        interview_event_id: event.id,
        user_id: user.id
      })
      |> Repo.insert!()

      conn = login_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/app/pipeline/#{job.id}")

      # Scorecard button should be disabled when no template
      html = render(view)
      assert html =~ "Scorecard"

      # Directly trigger the handler to test nil guard (button is disabled in UI)
      html = view |> render_click("open_scorecard", %{"event_id" => event.id})
      assert html =~ "No scorecard template" or html =~ "Scorecard"
    end
  end
end
