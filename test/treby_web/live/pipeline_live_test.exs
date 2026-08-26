defmodule TrebyWeb.PipelineLive.IndexTest do
  use TrebyWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias Treby.{Tenants, Repo}
  alias Treby.Accounts.User
  alias Treby.Candidates.Candidate
  alias Treby.Jobs.Job
  alias Treby.Pipeline.PipelineStage

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

    test "schedules email when moving candidate with schedule", %{conn: conn} do
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

      assert render(view) =~ "Candidate moved and email scheduled"

      queued =
        Repo.get_by!(Treby.EmailQueue.ScheduledEmail, to_address: "pipe-schedule@example.com")

      assert queued.email_type == "stage_change"
      assert queued.subject == "Interview Invite"

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

      assert render(view) =~ "DUPLICATE APP"
    end
  end
end
