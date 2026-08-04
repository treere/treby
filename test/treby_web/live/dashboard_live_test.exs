defmodule TrebyWeb.DashboardLiveTest do
  use TrebyWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias Treby.{Tenants, Repo}
  alias Treby.Accounts.User

  defp setup_tenant do
    {:ok, tenant} =
      Tenants.create_tenant(%{
        name: "Dashboard Test Corp",
        slug: "dash-test-#{System.unique_integer([:positive])}"
      })

    {:ok, user} =
      tenant
      |> Ecto.build_assoc(:users)
      |> User.changeset(%{
        email: "dash-#{System.unique_integer([:positive])}@test.com",
        password: "password123",
        name: "Dash User",
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

  describe "onboarding checklist" do
    test "shows checklist for new user with no data", %{conn: conn} do
      {_tenant, user} = setup_tenant()
      conn = login_user(conn, user)

      {:ok, view, _html} = live(conn, ~p"/app")

      html = render(view)
      assert html =~ "Get Started with Treby"
      assert html =~ "Create a job posting"
      assert html =~ "Add your first candidate"
      assert html =~ "Invite your team"
      assert html =~ "Customize your career page"
      assert html =~ "0 of 4 steps complete"
    end

    test "shows partial progress when some steps are complete", %{conn: conn} do
      {tenant, user} = setup_tenant()

      {:ok, pipeline} =
        Treby.Pipeline.create_pipeline(%{
          name: "Default",
          tenant_id: tenant.id,
          is_default: true
        })

      {:ok, _job} =
        tenant
        |> Ecto.build_assoc(:jobs)
        |> Treby.Jobs.Job.changeset(%{
          title: "Software Engineer",
          description: "Build things",
          pipeline_id: pipeline.id
        })
        |> Repo.insert()

      conn = login_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/app")

      html = render(view)
      assert html =~ "Get Started with Treby"
      assert html =~ "1 of 4 steps complete"
      assert html =~ "bg-green-500"
    end

    test "hides checklist when all steps are complete", %{conn: conn} do
      {tenant, user} = setup_tenant()

      # Create a job
      {:ok, pipeline} =
        Treby.Pipeline.create_pipeline(%{
          name: "Default",
          tenant_id: tenant.id,
          is_default: true
        })

      {:ok, _job} =
        tenant
        |> Ecto.build_assoc(:jobs)
        |> Treby.Jobs.Job.changeset(%{
          title: "Software Engineer",
          description: "Build things",
          pipeline_id: pipeline.id
        })
        |> Repo.insert()

      # Create a candidate
      {:ok, _candidate} =
        tenant
        |> Ecto.build_assoc(:candidates)
        |> Treby.Candidates.Candidate.changeset(%{
          name: "John Doe",
          email: "john@example.com"
        })
        |> Repo.insert()

      # Create a career page
      {:ok, _career_page} =
        tenant
        |> Ecto.build_assoc(:career_pages)
        |> Treby.Careers.CareerPage.changeset(%{
          title: "Join Us",
          primary_color: "#3b82f6"
        })
        |> Repo.insert()

      # Create a team member
      {:ok, _member} =
        tenant
        |> Ecto.build_assoc(:users)
        |> User.changeset(%{
          email: "member-#{System.unique_integer([:positive])}@test.com",
          password: "password123",
          name: "Team Member",
          role: "member"
        })
        |> Repo.insert()

      conn = login_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/app")

      html = render(view)
      refute html =~ "Get Started with Treby"
    end

    test "session dismiss hides checklist for current page load", %{conn: conn} do
      {_tenant, user} = setup_tenant()
      conn = login_user(conn, user)

      {:ok, view, _html} = live(conn, ~p"/app")

      html = render(view)
      assert html =~ "Get Started with Treby"

      render_click(view, "dismiss-onboarding", %{})

      html = render(view)
      refute html =~ "Get Started with Treby"
    end

    test "permanent dismiss persists to database", %{conn: conn} do
      {_tenant, user} = setup_tenant()
      conn = login_user(conn, user)

      {:ok, view, _html} = live(conn, ~p"/app")

      render_click(view, "dismiss-onboarding", %{"dismiss" => "permanent"})

      # Reload user from DB
      user = Repo.get!(User, user.id)
      assert user.onboarding_checklist_dismissed == true
    end

    test "permanent dismiss hides checklist on reload", %{conn: conn} do
      {_tenant, user} = setup_tenant()

      # Set dismissed in DB
      {:ok, user} = Treby.Accounts.dismiss_onboarding_checklist(user)

      conn = login_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/app")

      html = render(view)
      refute html =~ "Get Started with Treby"
    end
  end

  describe "dashboard empty states" do
    test "shows empty state for pipeline overview when no jobs", %{conn: conn} do
      {_tenant, user} = setup_tenant()
      conn = login_user(conn, user)

      {:ok, view, _html} = live(conn, ~p"/app")

      html = render(view)
      assert html =~ "No open jobs yet"
      assert html =~ "Create your first job"
    end

    test "shows empty state for upcoming interviews", %{conn: conn} do
      {_tenant, user} = setup_tenant()
      conn = login_user(conn, user)

      {:ok, view, _html} = live(conn, ~p"/app")

      html = render(view)
      assert html =~ "No upcoming interviews"
    end

    test "shows empty state for stale candidates", %{conn: conn} do
      {_tenant, user} = setup_tenant()
      conn = login_user(conn, user)

      {:ok, view, _html} = live(conn, ~p"/app")

      html = render(view)
      assert html =~ "No stale candidates"
    end

    test "shows stat cards and pipeline with data, empty states for sections without data", %{
      conn: conn
    } do
      {tenant, user} = setup_tenant()

      pipeline_id = Treby.Pipeline.default_pipeline_id(tenant.id)
      pipeline = Treby.Repo.get!(Treby.Pipeline.Pipeline, pipeline_id)

      {:ok, stage} =
        pipeline
        |> Ecto.build_assoc(:pipeline_stages)
        |> Treby.Pipeline.PipelineStage.changeset(%{
          name: "Applied",
          position: 0,
          stage_type: "applied"
        })
        |> Repo.insert()

      {:ok, job} =
        tenant
        |> Ecto.build_assoc(:jobs)
        |> Treby.Jobs.Job.changeset(%{
          title: "Software Engineer",
          description: "Build things",
          pipeline_id: pipeline_id
        })
        |> Repo.insert()

      {:ok, candidate} =
        tenant
        |> Ecto.build_assoc(:candidates)
        |> Treby.Candidates.Candidate.changeset(%{
          name: "Jane Smith",
          email: "jane@example.com"
        })
        |> Repo.insert()

      {:ok, _application} =
        tenant
        |> Ecto.build_assoc(:applications)
        |> Ecto.Changeset.change(%{
          job_id: job.id,
          candidate_id: candidate.id,
          pipeline_stage_id: stage.id,
          applied_at: DateTime.utc_now() |> DateTime.truncate(:second),
          inserted_at: DateTime.utc_now()
        })
        |> Repo.insert()

      conn = login_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/app")

      html = render(view)

      # Stat cards are present with labels
      assert html =~ "Applications This Week"
      assert html =~ "Interviews This Week"

      # Pipeline shows the job (not the empty state)
      refute html =~ "No open jobs yet"
      assert html =~ "Software Engineer"

      # Sections without data still show their empty states
      assert html =~ "No upcoming interviews"
    end
  end
end
