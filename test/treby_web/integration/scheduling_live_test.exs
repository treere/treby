defmodule TrebyWeb.SchedulingLiveTest do
  use TrebyWeb.ConnCase, async: false

  import Ecto.Query
  import Phoenix.LiveViewTest

  alias Treby.{Tenants, Pipeline, Calendar, Repo}
  alias Treby.Accounts.User
  alias Treby.Candidates.Candidate
  alias Treby.Jobs.Job

  defp setup_interviewer(tenant) do
    {:ok, user} =
      tenant
      |> Ecto.build_assoc(:users)
      |> User.changeset(%{
        email: "interviewer-#{System.unique_integer([:positive])}@test.com",
        password: "password123",
        name: "Interviewer User",
        role: "admin"
      })
      |> Repo.insert()

    # Create a calendar connection for the user
    {:ok, _} =
      Calendar.connect_google_user(user.id, tenant.id, %{
        access_token: "test-access-token",
        refresh_token: "test-refresh-token",
        expires_at: DateTime.utc_now() |> DateTime.add(1, :hour),
        email: user.email
      })

    user
  end

  defp setup_candidate_and_app(tenant) do
    {:ok, job} =
      tenant
      |> Ecto.build_assoc(:jobs)
      |> Job.changeset(%{
        title: "Test Engineer",
        description: "A test job"
      })
      |> Repo.insert()

    {:ok, candidate} =
      tenant
      |> Ecto.build_assoc(:candidates)
      |> Candidate.changeset(%{
        name: "Test Candidate",
        email: "candidate-#{System.unique_integer([:positive])}@test.com"
      })
      |> Repo.insert()

    pipeline_id = job.pipeline_id || Treby.Pipeline.default_pipeline_id(job.tenant_id)

    stage =
      Repo.one!(from s in Pipeline.PipelineStage, where: s.pipeline_id == ^pipeline_id, limit: 1)

    {:ok, application} =
      tenant
      |> Ecto.build_assoc(:applications)
      |> Ecto.Changeset.change(%{
        job_id: job.id,
        candidate_id: candidate.id,
        pipeline_stage_id: stage.id,
        applied_at: DateTime.utc_now() |> DateTime.truncate(:second)
      })
      |> Repo.insert()

    {job, candidate, application}
  end

  defp setup_tenant_and_user do
    {:ok, tenant} =
      Tenants.create_tenant(%{
        name: "Scheduling Test Corp",
        slug: "scheduling-test-#{System.unique_integer([:positive])}"
      })

    {:ok, user} =
      tenant
      |> Ecto.build_assoc(:users)
      |> User.changeset(%{
        email: "admin-#{System.unique_integer([:positive])}@test.com",
        password: "password123",
        name: "Admin User",
        role: "admin"
      })
      |> Repo.insert()

    {tenant, user}
  end

  describe "InterviewsLive.Index" do
    test "mounts and renders interviews page", %{conn: conn} do
      {tenant, user} = setup_tenant_and_user()

      conn =
        conn
        |> init_test_session(%{"user_id" => user.id, "tenant_id" => tenant.id})

      {:ok, view, _html} = live(conn, ~p"/app/interviews")

      assert has_element?(view, "h1", "Interviews")
      assert has_element?(view, "p", "Manage and view all scheduled interviews")
    end

    test "shows empty state when no interviews", %{conn: conn} do
      {tenant, user} = setup_tenant_and_user()

      conn =
        conn
        |> init_test_session(%{"user_id" => user.id, "tenant_id" => tenant.id})

      {:ok, view, _html} = live(conn, ~p"/app/interviews")

      assert has_element?(view, "p", "No interviews scheduled yet")
    end

    test "shows interviews when scheduled", %{conn: conn} do
      {tenant, user} = setup_tenant_and_user()
      interviewer = setup_interviewer(tenant)
      {_job, _candidate, app} = setup_candidate_and_app(tenant)

      {:ok, _event} =
        Treby.Interviews.schedule_interview(%{
          start_at_utc: DateTime.add(DateTime.utc_now(), 1, :day),
          end_at_utc: DateTime.add(DateTime.utc_now(), 1, :day) |> DateTime.add(1800, :second),
          duration_minutes: 30,
          interviewer_id: interviewer.id,
          scheduled_by_id: user.id,
          application_id: app.id,
          tenant_id: tenant.id
        })

      conn =
        conn
        |> init_test_session(%{"user_id" => user.id, "tenant_id" => tenant.id})

      {:ok, view, _html} = live(conn, ~p"/app/interviews")

      assert has_element?(view, "h3", "Test Candidate")
      assert has_element?(view, "span", "Test Engineer")
    end

    test "can switch to my interviews view", %{conn: conn} do
      {tenant, user} = setup_tenant_and_user()

      conn =
        conn
        |> init_test_session(%{"user_id" => user.id, "tenant_id" => tenant.id})

      {:ok, view, _html} = live(conn, ~p"/app/interviews")

      view |> element("button", "My Interviews") |> render_click()

      html = render(view)
      assert html =~ "No interviews scheduled yet"
    end
  end

  describe "ScheduleLive.Index" do
    test "mounts and renders scheduling page", %{conn: conn} do
      {tenant, user} = setup_tenant_and_user()
      {_job, _candidate, app} = setup_candidate_and_app(tenant)

      conn =
        conn
        |> init_test_session(%{"user_id" => user.id, "tenant_id" => tenant.id})

      {:ok, view, _html} = live(conn, ~p"/app/schedule/#{app.id}")

      assert has_element?(view, "h1", "Schedule Interview")
      assert has_element?(view, "strong", "Test Candidate")

      html = render(view)
      assert html =~ "Test Engineer"
    end

    test "shows message when no connected users", %{conn: conn} do
      {tenant, user} = setup_tenant_and_user()
      {_job, _candidate, app} = setup_candidate_and_app(tenant)

      conn =
        conn
        |> init_test_session(%{"user_id" => user.id, "tenant_id" => tenant.id})

      {:ok, view, _html} = live(conn, ~p"/app/schedule/#{app.id}")

      assert has_element?(view, "p", "No team members have connected their Google Calendar yet.")
    end

    test "shows connected users for interviewer selection", %{conn: conn} do
      {tenant, user} = setup_tenant_and_user()
      _interviewer = setup_interviewer(tenant)
      {_job, _candidate, app} = setup_candidate_and_app(tenant)

      conn =
        conn
        |> init_test_session(%{"user_id" => user.id, "tenant_id" => tenant.id})

      {:ok, view, _html} = live(conn, ~p"/app/schedule/#{app.id}")

      assert has_element?(view, "span", "Interviewer User")
    end

    test "can generate booking link", %{conn: conn} do
      {tenant, user} = setup_tenant_and_user()
      {_job, _candidate, app} = setup_candidate_and_app(tenant)

      conn =
        conn
        |> init_test_session(%{"user_id" => user.id, "tenant_id" => tenant.id})

      {:ok, view, _html} = live(conn, ~p"/app/schedule/#{app.id}")

      view |> element("button", "Generate Booking Link") |> render_click()

      html = render(view)
      assert html =~ "Share this link with the candidate"
      assert html =~ "/scheduling-test-"
    end
  end
end
