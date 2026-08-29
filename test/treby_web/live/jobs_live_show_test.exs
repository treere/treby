defmodule TrebyWeb.JobsLive.ShowPipelineTest do
  use TrebyWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias Treby.{Tenants, Repo, Pipeline}
  alias Treby.Accounts.User
  alias Treby.Candidates.Candidate
  alias Treby.Jobs.Job
  alias Treby.Pipeline.PipelineStage
  alias Treby.Interviews.InterviewEvent

  defp setup_tenant(role \\ "admin") do
    {:ok, tenant} =
      Tenants.create_tenant(%{
        name: "Job Show Corp",
        slug: "job-show-#{System.unique_integer([:positive])}"
      })

    {:ok, user} =
      tenant
      |> Ecto.build_assoc(:users)
      |> User.changeset(%{
        email: "jobshow-#{System.unique_integer([:positive])}@test.com",
        password: "password123",
        name: "Job Show User",
        role: role
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

  defp create_job(tenant, pipeline_id) do
    {:ok, job} =
      tenant
      |> Ecto.build_assoc(:jobs)
      |> Job.changeset(%{
        title: "Software Engineer",
        description: "Build things",
        pipeline_id: pipeline_id
      })
      |> Repo.insert()

    job
  end

  defp create_application(tenant, job, stage, name, email) do
    {:ok, candidate} =
      tenant
      |> Ecto.build_assoc(:candidates)
      |> Candidate.changeset(%{name: name, email: email})
      |> Repo.insert()

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

  defp job_show_live(conn, job) do
    {:ok, view, _html} = live(conn, ~p"/app/jobs/#{job.id}")
    view
  end

  defp stage_btn(event, stage_id) do
    ~s(button[phx-click="#{event}"][phx-value-stage_id="#{stage_id}"])
  end

  defp open_pipeline_manager(view) do
    view |> element("button", "Manage Pipeline") |> render_click()
  end

  describe "pipeline editor on job page" do
    test "lists stages of the job's pipeline", %{conn: conn} do
      {tenant, user} = setup_tenant()
      default_id = Pipeline.default_pipeline_id(tenant.id)
      job = create_job(tenant, default_id)

      conn = login_user(conn, user)
      view = job_show_live(conn, job)

      assert has_element?(view, "#job-stage-form") == false
      html = render(view)
      assert html =~ "Pipeline"
      assert html =~ "New"
      assert html =~ "Offer"
    end

    test "adds a new stage to the job's pipeline", %{conn: conn} do
      {tenant, user} = setup_tenant()
      default_id = Pipeline.default_pipeline_id(tenant.id)
      job = create_job(tenant, default_id)
      original_count = length(Pipeline.list_pipeline_stages(default_id))

      conn = login_user(conn, user)
      view = job_show_live(conn, job)
      open_pipeline_manager(view)

      view |> element("button", "Add Stage") |> render_click()

      view
      |> form("#job-stage-form", %{
        "pipeline_stage" => %{"name" => "Final Review", "stage_type" => "interview"}
      })
      |> render_submit()

      html = render(view)
      assert html =~ "Final Review"

      assert length(Pipeline.list_pipeline_stages(Pipeline.job_effective_pipeline_id(job))) ==
               original_count + 1
    end

    test "edits a stage name and color", %{conn: conn} do
      {tenant, user} = setup_tenant()
      default_id = Pipeline.default_pipeline_id(tenant.id)
      job = create_job(tenant, default_id)
      stages = Pipeline.list_pipeline_stages(default_id)
      stage = Enum.find(stages, &(&1.name == "Screen"))

      conn = login_user(conn, user)
      view = job_show_live(conn, job)
      open_pipeline_manager(view)

      view
      |> element(stage_btn("edit_stage", stage.id))
      |> render_click()

      view
      |> form("#job-stage-form", %{
        "pipeline_stage" => %{
          "name" => "Screening",
          "stage_type" => "new",
          "color" => "#111111"
        }
      })
      |> render_submit()

      html = render(view)
      assert html =~ "Screening"

      updated = Repo.get!(PipelineStage, stage.id)
      assert updated.name == "Screening"
      assert updated.color == "#111111"
    end

    test "reorders stages up", %{conn: conn} do
      {tenant, user} = setup_tenant()
      default_id = Pipeline.default_pipeline_id(tenant.id)
      job = create_job(tenant, default_id)
      stages = Pipeline.list_pipeline_stages(default_id)
      target = Enum.find(stages, &(&1.name == "Offer"))

      conn = login_user(conn, user)
      view = job_show_live(conn, job)
      open_pipeline_manager(view)

      view
      |> element(stage_btn("move_stage_up", target.id))
      |> render_click()

      render(view)

      updated = Repo.reload!(target)
      assert updated.position < target.position
    end
  end

  describe "delete stage" do
    test "prevents deleting the only new stage", %{conn: conn} do
      {tenant, user} = setup_tenant()
      default_id = Pipeline.default_pipeline_id(tenant.id)
      job = create_job(tenant, default_id)
      new_stage = Enum.find(Pipeline.list_pipeline_stages(default_id), &(&1.stage_type == "new"))

      conn = login_user(conn, user)
      view = job_show_live(conn, job)
      open_pipeline_manager(view)

      view
      |> element(stage_btn("delete_stage", new_stage.id))
      |> render_click()

      assert render(view) =~ "Cannot delete the only entry stage"
      assert Repo.get(PipelineStage, new_stage.id)
    end

    test "shows reassignment modal when deleting a stage with candidates", %{conn: conn} do
      {tenant, user} = setup_tenant()
      default_id = Pipeline.default_pipeline_id(tenant.id)
      job = create_job(tenant, default_id)
      stage = Enum.find(Pipeline.list_pipeline_stages(default_id), &(&1.name == "Screen"))

      {:ok, candidate} =
        tenant
        |> Ecto.build_assoc(:candidates)
        |> Candidate.changeset(%{name: "Del Candidate", email: "del@example.com"})
        |> Repo.insert()

      Pipeline.create_application(%{
        tenant_id: tenant.id,
        job_id: job.id,
        candidate_id: candidate.id,
        pipeline_stage_id: stage.id,
        applied_at: DateTime.utc_now()
      })

      conn = login_user(conn, user)
      view = job_show_live(conn, job)
      open_pipeline_manager(view)

      view
      |> element(stage_btn("delete_stage", stage.id))
      |> render_click()

      assert render(view) =~ "Reassign candidates"
    end
  end

  describe "stage roles" do
    test "assigns an examiner role to a stage", %{conn: conn} do
      {tenant, user} = setup_tenant()
      default_id = Pipeline.default_pipeline_id(tenant.id)
      job = create_job(tenant, default_id)

      interview =
        Enum.find(Pipeline.list_pipeline_stages(default_id), &(&1.stage_type == "interview"))

      conn = login_user(conn, user)
      view = job_show_live(conn, job)
      open_pipeline_manager(view)

      view
      |> element(stage_btn("show_roles", interview.id))
      |> render_click()

      assert render(view) =~ "Roles for"

      view
      |> form("#job-add-examiner-form", %{"stage_id" => interview.id, "user_id" => user.id})
      |> render_submit()

      assert length(Pipeline.list_examiners(interview)) == 1
    end
  end

  describe "pipeline read-only overview" do
    test "shows a read-only overview by default for admins", %{conn: conn} do
      {tenant, user} = setup_tenant()
      default_id = Pipeline.default_pipeline_id(tenant.id)
      job = create_job(tenant, default_id)

      conn = login_user(conn, user)
      view = job_show_live(conn, job)

      html = render(view)
      assert html =~ "Pipeline"
      assert html =~ "Manage Pipeline"
      refute html =~ "Add Stage"
      refute has_element?(view, ~s(button[phx-click="edit_stage"]))
      refute has_element?(view, ~s(button[phx-click="delete_stage"]))
      refute has_element?(view, ~s(button[phx-click="move_stage_up"]))
    end

    test "reveals the editor after clicking Manage Pipeline", %{conn: conn} do
      {tenant, user} = setup_tenant()
      default_id = Pipeline.default_pipeline_id(tenant.id)
      job = create_job(tenant, default_id)

      conn = login_user(conn, user)
      view = job_show_live(conn, job)

      open_pipeline_manager(view)

      assert has_element?(view, "button", "Add Stage")
      assert has_element?(view, ~s(button[phx-click="edit_stage"]))
      assert has_element?(view, ~s(button[phx-click="delete_stage"]))
    end

    test "shows assigned role names in the overview", %{conn: conn} do
      {tenant, user} = setup_tenant()
      default_id = Pipeline.default_pipeline_id(tenant.id)
      job = create_job(tenant, default_id)

      interview =
        Enum.find(Pipeline.list_pipeline_stages(default_id), &(&1.stage_type == "interview"))

      Pipeline.assign_examiner(interview, user.id)

      conn = login_user(conn, user)
      view = job_show_live(conn, job)

      assert render(view) =~ user.name
    end

    test "non-admin sees the overview without a Manage Pipeline button", %{conn: conn} do
      {tenant, user} = setup_tenant("member")
      default_id = Pipeline.default_pipeline_id(tenant.id)
      job = create_job(tenant, default_id)

      conn = login_user(conn, user)
      view = job_show_live(conn, job)

      html = render(view)
      refute html =~ "Manage Pipeline"
      refute html =~ "Add Stage"
      refute has_element?(view, ~s(button[phx-click="edit_stage"]))
      refute has_element?(view, ~s(button[phx-click="delete_stage"]))
    end
  end

  describe "job page candidate workspace" do
    test "groups candidates by stage with counts", %{conn: conn} do
      {tenant, user} = setup_tenant()
      default_id = Pipeline.default_pipeline_id(tenant.id)
      job = create_job(tenant, default_id)
      stages = Pipeline.list_pipeline_stages(default_id)
      screen = Enum.find(stages, &(&1.name == "Screen"))
      offer = Enum.find(stages, &(&1.name == "Offer"))

      app1 = create_application(tenant, job, screen, "Screen Candidate", "screen@example.com")
      app2 = create_application(tenant, job, offer, "Offer Candidate", "offer@example.com")

      conn = login_user(conn, user)
      view = job_show_live(conn, job)

      html = render(view)
      assert html =~ "Screen Candidate"
      assert html =~ "Offer Candidate"
      assert has_element?(view, "#stage-#{screen.id}")
      assert has_element?(view, "#stage-#{offer.id}")
      assert has_element?(view, "#job-candidate-#{app1.id}")
      assert has_element?(view, "#job-candidate-#{app2.id}")
    end

    test "moves a candidate to another stage via the selector", %{conn: conn} do
      {tenant, user} = setup_tenant()
      default_id = Pipeline.default_pipeline_id(tenant.id)
      job = create_job(tenant, default_id)
      stages = Pipeline.list_pipeline_stages(default_id)
      screen = Enum.find(stages, &(&1.name == "Screen"))
      offer = Enum.find(stages, &(&1.name == "Offer"))
      app = create_application(tenant, job, screen, "Mover", "mover@example.com")

      conn = login_user(conn, user)
      view = job_show_live(conn, job)

      view
      |> render_change("move_application", %{
        "application_id" => app.id,
        "stage_id" => offer.id
      })

      assert Repo.get!(Treby.Pipeline.Application, app.id).pipeline_stage_id == offer.id
      assert has_element?(view, "#stage-#{offer.id} #job-candidate-#{app.id}")
      refute has_element?(view, "#stage-#{screen.id} #job-candidate-#{app.id}")
    end

    test "disables the selector for non-advancers on interview stages", %{conn: conn} do
      {tenant, user} = setup_tenant("member")
      default_id = Pipeline.default_pipeline_id(tenant.id)
      job = create_job(tenant, default_id)

      interview =
        Enum.find(Pipeline.list_pipeline_stages(default_id), &(&1.stage_type == "interview"))

      app = create_application(tenant, job, interview, "Interview App", "interview@example.com")

      conn = login_user(conn, user)
      view = job_show_live(conn, job)

      assert has_element?(view, ~s(select#move-select-#{app.id}[disabled]))
    end

    test "disables the selector when the pipeline has a single stage", %{conn: conn} do
      {tenant, user} = setup_tenant()
      {:ok, pipeline} = Pipeline.create_pipeline(%{name: "Solo Pipeline", tenant_id: tenant.id})

      {:ok, stage} =
        Pipeline.create_pipeline_stage(%{
          name: "Solo Stage",
          pipeline_id: pipeline.id,
          position: 0,
          color: "#3b82f6"
        })

      job = create_job(tenant, pipeline.id)
      app = create_application(tenant, job, stage, "Solo App", "solo@example.com")

      conn = login_user(conn, user)
      view = job_show_live(conn, job)

      assert has_element?(view, ~s(select#move-select-#{app.id}[disabled]))
    end
  end

  describe "job page candidate actions" do
    test "toggles review state on a candidate card", %{conn: conn} do
      {tenant, user} = setup_tenant()
      default_id = Pipeline.default_pipeline_id(tenant.id)
      job = create_job(tenant, default_id)
      new_stage = Enum.find(Pipeline.list_pipeline_stages(default_id), &(&1.stage_type == "new"))
      app = create_application(tenant, job, new_stage, "Review Me", "review@example.com")

      conn = login_user(conn, user)
      view = job_show_live(conn, job)

      view |> render_click("toggle_review", %{"application_id" => app.id})

      assert Repo.get!(Treby.Pipeline.Application, app.id).reviewed == true
      assert render(view) =~ "Reviewed"
    end

    test "rejects a candidate with a motivation", %{conn: conn} do
      {tenant, user} = setup_tenant()
      default_id = Pipeline.default_pipeline_id(tenant.id)
      job = create_job(tenant, default_id)
      new_stage = Enum.find(Pipeline.list_pipeline_stages(default_id), &(&1.stage_type == "new"))
      app = create_application(tenant, job, new_stage, "Reject Me", "reject@example.com")

      conn = login_user(conn, user)
      view = job_show_live(conn, job)

      view |> render_click("reject_application", %{"application_id" => app.id})
      assert render(view) =~ "Reject Candidate"

      view |> render_change("update_rejection_reason", %{"value" => "not a fit"})
      view |> render_click("confirm_reject")

      rejected_stage =
        Enum.find(Pipeline.list_pipeline_stages(default_id), &(&1.stage_type == "rejected"))

      updated = Repo.get!(Treby.Pipeline.Application, app.id)
      assert updated.pipeline_stage_id == rejected_stage.id
      assert updated.rejection_reason == "not a fit"
    end

    test "rejection requires a motivation", %{conn: conn} do
      {tenant, user} = setup_tenant()
      default_id = Pipeline.default_pipeline_id(tenant.id)
      job = create_job(tenant, default_id)
      new_stage = Enum.find(Pipeline.list_pipeline_stages(default_id), &(&1.stage_type == "new"))
      app = create_application(tenant, job, new_stage, "No Reason", "noreason@example.com")

      conn = login_user(conn, user)
      view = job_show_live(conn, job)

      view |> render_click("reject_application", %{"application_id" => app.id})
      view |> render_click("confirm_reject")

      assert render(view) =~ "Rejection motivation is required"
      assert Repo.get!(Treby.Pipeline.Application, app.id).pipeline_stage_id == new_stage.id
    end

    test "searches candidates by name or email", %{conn: conn} do
      {tenant, user} = setup_tenant()
      default_id = Pipeline.default_pipeline_id(tenant.id)
      job = create_job(tenant, default_id)
      new_stage = Enum.find(Pipeline.list_pipeline_stages(default_id), &(&1.stage_type == "new"))
      app1 = create_application(tenant, job, new_stage, "Alice Smith", "alice@example.com")
      app2 = create_application(tenant, job, new_stage, "Bob Jones", "bob@example.com")

      conn = login_user(conn, user)
      view = job_show_live(conn, job)

      view |> render_keyup("search_candidates", %{"candidate_search" => "alice"})

      assert has_element?(view, "#job-candidate-#{app1.id}")
      refute has_element?(view, "#job-candidate-#{app2.id}")

      view |> render_keyup("search_candidates", %{"candidate_search" => "zzz"})

      refute has_element?(view, "#job-candidate-#{app1.id}")
      refute has_element?(view, "#job-candidate-#{app2.id}")
    end
  end

  describe "job page candidate badges" do
    test "shows a DUPLICATE badge for duplicate applications", %{conn: conn} do
      {tenant, user} = setup_tenant()
      default_id = Pipeline.default_pipeline_id(tenant.id)
      job = create_job(tenant, default_id)
      new_stage = Enum.find(Pipeline.list_pipeline_stages(default_id), &(&1.stage_type == "new"))

      {:ok, candidate} =
        tenant
        |> Ecto.build_assoc(:candidates)
        |> Candidate.changeset(%{name: "Dup Candidate", email: "dup@example.com"})
        |> Repo.insert()

      {:ok, _first} =
        Pipeline.create_application(%{
          tenant_id: tenant.id,
          job_id: job.id,
          candidate_id: candidate.id,
          pipeline_stage_id: new_stage.id,
          applied_at: DateTime.utc_now()
        })

      {:ok, second} =
        Pipeline.create_application(%{
          tenant_id: tenant.id,
          job_id: job.id,
          candidate_id: candidate.id,
          pipeline_stage_id: new_stage.id,
          applied_at: DateTime.utc_now()
        })

      assert second.is_duplicate == true

      conn = login_user(conn, user)
      view = job_show_live(conn, job)

      assert render(view) =~ "DUPLICATE"
    end

    test "shows the other positions indicator", %{conn: conn} do
      {tenant, user} = setup_tenant()
      default_id = Pipeline.default_pipeline_id(tenant.id)
      job_a = create_job(tenant, default_id)
      job_b = create_job(tenant, default_id)
      new_stage = Enum.find(Pipeline.list_pipeline_stages(default_id), &(&1.stage_type == "new"))

      {:ok, candidate} =
        tenant
        |> Ecto.build_assoc(:candidates)
        |> Candidate.changeset(%{name: "Multi Job", email: "multi@example.com"})
        |> Repo.insert()

      Pipeline.create_application(%{
        tenant_id: tenant.id,
        job_id: job_a.id,
        candidate_id: candidate.id,
        pipeline_stage_id: new_stage.id,
        applied_at: DateTime.utc_now()
      })

      Pipeline.create_application(%{
        tenant_id: tenant.id,
        job_id: job_b.id,
        candidate_id: candidate.id,
        pipeline_stage_id: new_stage.id,
        applied_at: DateTime.utc_now()
      })

      conn = login_user(conn, user)
      view = job_show_live(conn, job_a)

      assert render(view) =~ "Also in 1 other position"
    end

    test "shows an upcoming interview chip", %{conn: conn} do
      {tenant, user} = setup_tenant()
      default_id = Pipeline.default_pipeline_id(tenant.id)
      job = create_job(tenant, default_id)
      new_stage = Enum.find(Pipeline.list_pipeline_stages(default_id), &(&1.stage_type == "new"))
      app = create_application(tenant, job, new_stage, "Interview Soon", "soon@example.com")

      start = DateTime.add(DateTime.utc_now(), 3600)

      %InterviewEvent{}
      |> InterviewEvent.changeset(%{
        application_id: app.id,
        tenant_id: tenant.id,
        start_at_utc: start,
        end_at_utc: DateTime.add(start, 60),
        duration_minutes: 60,
        status: "scheduled"
      })
      |> Repo.insert!()

      conn = login_user(conn, user)
      view = job_show_live(conn, job)

      assert render(view) =~ Calendar.strftime(start, "%b %d %H:%M")
    end

    test "shows a resume link when the application has a resume", %{conn: conn} do
      {tenant, user} = setup_tenant()
      default_id = Pipeline.default_pipeline_id(tenant.id)
      job = create_job(tenant, default_id)
      new_stage = Enum.find(Pipeline.list_pipeline_stages(default_id), &(&1.stage_type == "new"))

      {:ok, candidate} =
        tenant
        |> Ecto.build_assoc(:candidates)
        |> Candidate.changeset(%{name: "Has Resume", email: "resume@example.com"})
        |> Repo.insert()

      {:ok, application} =
        Pipeline.create_application(%{
          tenant_id: tenant.id,
          job_id: job.id,
          candidate_id: candidate.id,
          pipeline_stage_id: new_stage.id,
          applied_at: DateTime.utc_now(),
          resume_url: "/uploads/resume.pdf"
        })

      conn = login_user(conn, user)
      view = job_show_live(conn, job)

      assert render(view) =~ ~p"/app/applications/#{application.id}/resume"
    end
  end

  describe "job page candidate gating" do
    test "non-advancer does not see the reject button on an interview stage", %{conn: conn} do
      {tenant, user} = setup_tenant("member")
      default_id = Pipeline.default_pipeline_id(tenant.id)
      job = create_job(tenant, default_id)

      interview =
        Enum.find(Pipeline.list_pipeline_stages(default_id), &(&1.stage_type == "interview"))

      create_application(tenant, job, interview, "Gated Reject", "gated@example.com")

      conn = login_user(conn, user)
      view = job_show_live(conn, job)

      refute has_element?(view, ~s(button[phx-click="reject_application"]))
    end

    test "reject button is disabled when the pipeline has no rejected stage", %{conn: conn} do
      {tenant, user} = setup_tenant()
      {:ok, pipeline} = Pipeline.create_pipeline(%{name: "No Reject", tenant_id: tenant.id})

      {:ok, stage} =
        Pipeline.create_pipeline_stage(%{
          name: "Solo Stage",
          pipeline_id: pipeline.id,
          position: 0,
          color: "#3b82f6"
        })

      job = create_job(tenant, pipeline.id)
      create_application(tenant, job, stage, "No Reject", "noreject@example.com")

      conn = login_user(conn, user)
      view = job_show_live(conn, job)

      assert has_element?(view, ~s(button[phx-click="reject_application"][disabled]))
    end
  end

  describe "pipeline decoupling" do
    test "clones a shared pipeline when editing from the job page", %{conn: conn} do
      {tenant, user} = setup_tenant()
      default_id = Pipeline.default_pipeline_id(tenant.id)
      job_a = create_job(tenant, default_id)
      job_b = create_job(tenant, default_id)

      assert Pipeline.pipeline_shared?(default_id)

      conn = login_user(conn, user)
      view = job_show_live(conn, job_a)
      open_pipeline_manager(view)

      view |> element("button", "Add Stage") |> render_click()

      view
      |> form("#job-stage-form", %{
        "pipeline_stage" => %{"name" => "Custom Stage", "stage_type" => "new"}
      })
      |> render_submit()

      updated_job = Repo.get!(Job, job_a.id)
      refute updated_job.pipeline_id == default_id

      new_id = updated_job.pipeline_id

      # The other job still uses the original default pipeline, unchanged
      assert Repo.get!(Job, job_b.id).pipeline_id == default_id
      assert "New" in Enum.map(Pipeline.list_pipeline_stages(default_id), & &1.name)
      refute "Custom Stage" in Enum.map(Pipeline.list_pipeline_stages(default_id), & &1.name)

      # The clone carries the original stages plus the new one
      assert "Custom Stage" in Enum.map(Pipeline.list_pipeline_stages(new_id), & &1.name)
      assert "New" in Enum.map(Pipeline.list_pipeline_stages(new_id), & &1.name)
    end

    test "does not clone a pipeline used only by this job", %{conn: conn} do
      {tenant, user} = setup_tenant()
      default_id = Pipeline.default_pipeline_id(tenant.id)
      job = create_job(tenant, default_id)

      assert Pipeline.pipeline_shared?(default_id) == false

      conn = login_user(conn, user)
      view = job_show_live(conn, job)
      open_pipeline_manager(view)

      view |> element("button", "Add Stage") |> render_click()

      view
      |> form("#job-stage-form", %{
        "pipeline_stage" => %{"name" => "Solo Stage", "stage_type" => "new"}
      })
      |> render_submit()

      updated_job = Repo.get!(Job, job.id)
      assert updated_job.pipeline_id == default_id
    end

    test "remaps existing applications to the clone when decoupling a shared pipeline", %{
      conn: conn
    } do
      {tenant, user} = setup_tenant()
      default_id = Pipeline.default_pipeline_id(tenant.id)
      job = create_job(tenant, default_id)
      _other_job = create_job(tenant, default_id)

      new_stage = Enum.find(Pipeline.list_pipeline_stages(default_id), &(&1.stage_type == "new"))

      {:ok, candidate} =
        tenant
        |> Ecto.build_assoc(:candidates)
        |> Candidate.changeset(%{name: "Board Candidate", email: "board@example.com"})
        |> Repo.insert()

      {:ok, application} =
        Pipeline.create_application(%{
          tenant_id: tenant.id,
          job_id: job.id,
          candidate_id: candidate.id,
          pipeline_stage_id: new_stage.id,
          applied_at: DateTime.utc_now()
        })

      conn = login_user(conn, user)
      view = job_show_live(conn, job)
      open_pipeline_manager(view)

      view |> element("button", "Add Stage") |> render_click()

      view
      |> form("#job-stage-form", %{
        "pipeline_stage" => %{"name" => "Board Stage", "stage_type" => "new"}
      })
      |> render_submit()

      updated_job = Repo.get!(Job, job.id)
      refute updated_job.pipeline_id == default_id

      # The application was remapped to the clone's "New" stage, keeping it on the board
      cloned_new =
        Enum.find(
          Pipeline.list_pipeline_stages(updated_job.pipeline_id),
          &(&1.stage_type == "new")
        )

      assert cloned_new

      assert Repo.get!(Treby.Pipeline.Application, application.id).pipeline_stage_id ==
               cloned_new.id

      # The original shared pipeline and the other job are untouched
      assert Repo.get!(Treby.Pipeline.Application, application.id).job_id == job.id
      assert "New" in Enum.map(Pipeline.list_pipeline_stages(default_id), & &1.name)
    end
  end

  describe "non-admin access" do
    test "edit affordances are hidden and mutations are blocked", %{conn: conn} do
      {tenant, user} = setup_tenant("member")
      default_id = Pipeline.default_pipeline_id(tenant.id)
      job = create_job(tenant, default_id)

      conn = login_user(conn, user)
      view = job_show_live(conn, job)

      html = render(view)
      refute html =~ "Add Stage"
      refute html =~ ">Edit<"
      refute html =~ ">Delete<"
      refute html =~ "move_stage_up"
    end
  end
end
