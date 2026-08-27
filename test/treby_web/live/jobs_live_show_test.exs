defmodule TrebyWeb.JobsLive.ShowPipelineTest do
  use TrebyWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias Treby.{Tenants, Repo, Pipeline}
  alias Treby.Accounts.User
  alias Treby.Candidates.Candidate
  alias Treby.Jobs.Job
  alias Treby.Pipeline.PipelineStage

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

  defp job_show_live(conn, job) do
    {:ok, view, _html} = live(conn, ~p"/app/jobs/#{job.id}")
    view
  end

  defp stage_btn(event, stage_id) do
    ~s(button[phx-click="#{event}"][phx-value-stage_id="#{stage_id}"])
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

  describe "pipeline decoupling" do
    test "clones a shared pipeline when editing from the job page", %{conn: conn} do
      {tenant, user} = setup_tenant()
      default_id = Pipeline.default_pipeline_id(tenant.id)
      job_a = create_job(tenant, default_id)
      job_b = create_job(tenant, default_id)

      assert Pipeline.pipeline_shared?(default_id)

      conn = login_user(conn, user)
      view = job_show_live(conn, job_a)

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
