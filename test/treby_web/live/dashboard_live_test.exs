defmodule TrebyWeb.DashboardLiveTest do
  use TrebyWeb.ConnCase, async: false

  import Phoenix.LiveViewTest
  import Ecto.Query

  alias Treby.{Tenants, Repo}
  alias Treby.Accounts.User
  alias Treby.Candidates.Candidate
  alias Treby.Careers.CareerPage
  alias Treby.Jobs.Job
  alias Treby.Pipeline.PipelineStage

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
        |> Job.changeset(%{
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
        |> Job.changeset(%{
          title: "Software Engineer",
          description: "Build things",
          pipeline_id: pipeline.id
        })
        |> Repo.insert()

      # Create a candidate
      {:ok, _candidate} =
        tenant
        |> Ecto.build_assoc(:candidates)
        |> Candidate.changeset(%{
          name: "John Doe",
          email: "john@example.com"
        })
        |> Repo.insert()

      # Create a career page
      {:ok, _career_page} =
        tenant
        |> Ecto.build_assoc(:career_pages)
        |> CareerPage.changeset(%{
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

      {:ok, _} =
        Treby.Memberships.create_membership(%{
          user_id: _member.id,
          tenant_id: tenant.id,
          role: _member.role
        })

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

  describe "my actions panel" do
    test "shows empty state when there is nothing to do", %{conn: conn} do
      {_tenant, user} = setup_tenant()
      conn = login_user(conn, user)

      {:ok, view, _html} = live(conn, ~p"/app")

      html = render(view)
      assert html =~ "My Actions"
      assert html =~ "All caught up"
    end

    test "shows a pending scorecard for the current user", %{conn: conn} do
      {tenant, user} = setup_tenant()

      {:ok, app, _event} = setup_interview_application(tenant, user.id)

      conn = login_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/app")

      html = render(view)
      assert html =~ "My Actions"
      assert html =~ "Scorecards to fill"
      assert html =~ app.candidate.name
      assert html =~ "Fill scorecard"
    end

    test "does not show the pending scorecard once submitted", %{conn: conn} do
      {tenant, user} = setup_tenant()

      {:ok, _app, event} = setup_interview_application(tenant, user.id)

      Treby.Scorecards.submit_scorecard(event.id, user.id, %{
        "scores" => %{"Communication" => 4},
        "recommendation" => "hire",
        "notes" => "Great",
        "tenant_id" => tenant.id
      })

      conn = login_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/app")

      html = render(view)
      assert html =~ "My Actions"
      refute html =~ "Scorecards to fill"
    end

    test "opens scorecard form and submits it, removing the pending item", %{conn: conn} do
      {tenant, user} = setup_tenant()
      {:ok, _app, _event} = setup_interview_application(tenant, user.id)

      conn = login_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/app")

      view
      |> element("button", "Fill scorecard")
      |> render_click()

      html = render(view)
      assert html =~ "Scorecard"
      assert html =~ "Submit Scorecard"

      view
      |> form("#scorecard-form",
        recommendation: "hire",
        notes: "Great"
      )
      |> render_submit()

      html = render(view)
      assert html =~ "Scorecard submitted"
      refute html =~ "Scorecards to fill"
    end

    test "shows waiting on others section for blocked applications", %{conn: conn} do
      {tenant, user} = setup_tenant()

      {:ok, other_user} =
        tenant
        |> Ecto.build_assoc(:users)
        |> User.changeset(%{
          email: "other-#{System.unique_integer([:positive])}@test.com",
          password: "password123",
          name: "Other Examiner",
          role: "member"
        })
        |> Repo.insert()

      {:ok, _} =
        Treby.Memberships.create_membership(%{
          user_id: other_user.id,
          tenant_id: tenant.id,
          role: other_user.role
        })

      {:ok, _app, event} = setup_interview_application(tenant, user.id, other_user.id)

      # user submits; other_user still missing -> blocked by other
      Treby.Scorecards.submit_scorecard(event.id, user.id, %{
        "scores" => %{"Communication" => 4},
        "recommendation" => "hire",
        "notes" => "Great",
        "tenant_id" => tenant.id
      })

      Treby.Interviews.complete_interview(event)

      conn = login_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/app")

      html = render(view)
      assert html =~ "Waiting on others"
    end
  end

  defp setup_interview_application(tenant, examiner_ids) when is_list(examiner_ids) do
    pipeline_id = Treby.Pipeline.default_pipeline_id(tenant.id)

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
        name: "Jane Smith",
        email: "jane-#{System.unique_integer([:positive])}@example.com"
      })
      |> Repo.insert()

    stage =
      Repo.one!(
        from s in PipelineStage,
          where: s.stage_type == "interview" and s.pipeline_id == ^pipeline_id
      )

    {:ok, app} =
      tenant
      |> Ecto.build_assoc(:applications)
      |> Ecto.Changeset.change(%{
        job_id: job.id,
        candidate_id: candidate.id,
        pipeline_stage_id: stage.id,
        applied_at: DateTime.utc_now() |> DateTime.truncate(:second)
      })
      |> Repo.insert()

    now = DateTime.utc_now() |> DateTime.truncate(:second)

    {:ok, event} =
      %Treby.Interviews.InterviewEvent{}
      |> Ecto.Changeset.change(%{
        start_at_utc: DateTime.add(now, 1, :day),
        end_at_utc: DateTime.add(now, 1, :day) |> DateTime.add(1800, :second),
        duration_minutes: 30,
        status: "scheduled",
        application_id: app.id,
        tenant_id: tenant.id
      })
      |> Repo.insert()

    examiner_ids
    |> List.wrap()
    |> Enum.each(fn uid ->
      Repo.insert!(%Treby.Interviews.EventExaminer{
        interview_event_id: event.id,
        user_id: uid
      })
    end)

    {:ok, app, event}
  end

  defp setup_interview_application(tenant, examiner_id) do
    {:ok, app, event} = setup_interview_application(tenant, [examiner_id])
    {:ok, Repo.preload(app, :candidate), event}
  end

  defp setup_interview_application(tenant, examiner_id, other_examiner_id) do
    setup_interview_application(tenant, [examiner_id, other_examiner_id])
  end
end
