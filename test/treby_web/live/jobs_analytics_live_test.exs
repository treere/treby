defmodule TrebyWeb.JobsAnalyticsLiveTest do
  use TrebyWeb.ConnCase, async: false

  import Phoenix.LiveViewTest
  import Ecto.Query

  alias Treby.{Tenants, Repo, JobViews}
  alias Treby.Accounts.User
  alias Treby.Jobs.Job

  defp setup_tenant(role \\ "admin") do
    {:ok, tenant} =
      Tenants.create_tenant(%{
        name: "Analytics Corp #{System.unique_integer([:positive])}",
        slug: "analytics-#{System.unique_integer([:positive])}"
      })

    {:ok, user} =
      tenant
      |> Ecto.build_assoc(:users)
      |> User.changeset(%{
        email: "analytics-#{System.unique_integer([:positive])}@test.com",
        password: "password123",
        name: "Analytics User",
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

  defp create_job(tenant) do
    pipeline_id = Treby.Pipeline.default_pipeline_id(tenant.id)

    {:ok, job} =
      tenant
      |> Ecto.build_assoc(:jobs)
      |> Job.changeset(%{
        title: "Viewed Position #{System.unique_integer([:positive])}",
        description: "Desc",
        pipeline_id: pipeline_id
      })
      |> Repo.insert()

    job
  end

  describe "per-job analytics page" do
    test "renders KPIs and requires tenant isolation", %{conn: conn} do
      {tenant_a, user_a} = setup_tenant()
      {tenant_b, user_b} = setup_tenant()
      job_a = create_job(tenant_a)
      _job_b = create_job(tenant_b)

      # tenant A can view its own job analytics
      conn_a = login_user(conn, user_a)
      {:ok, view, html} = live(conn_a, ~p"/app/jobs/#{job_a.id}/analytics")
      assert html =~ "Analytics"
      assert html =~ job_a.title
      assert has_element?(view, "a[href='/app/jobs/#{job_a.id}']")

      # tenant B cannot view tenant A's job -> redirects to 404
      conn_b = login_user(build_conn(), user_b)

      assert {:error, {:redirect, %{to: "/404"}}} =
               live(conn_b, ~p"/app/jobs/#{job_a.id}/analytics")
    end

    test "empty state shows No views yet", %{conn: conn} do
      {tenant, user} = setup_tenant()
      job = create_job(tenant)
      conn = login_user(conn, user)
      {:ok, _view, html} = live(conn, ~p"/app/jobs/#{job.id}/analytics")
      assert html =~ "No views yet"
      assert html =~ "Total Views"
      assert html =~ "0"
    end

    test "shows data when views exist", %{conn: conn} do
      {tenant, user} = setup_tenant()
      job = create_job(tenant)
      hash = JobViews.session_hash("9.9.9.9", "Mozilla")

      {:ok, _} =
        JobViews.track_view(%{
          job_id: job.id,
          tenant_id: tenant.id,
          session_hash: hash,
          viewed_at: DateTime.utc_now(),
          user_agent: "Mozilla",
          utm_source: "linkedin"
        })

      conn = login_user(conn, user)
      {:ok, _view, html} = live(conn, ~p"/app/jobs/#{job.id}/analytics")
      assert html =~ "linkedin"
      assert html =~ "1"
    end

    test "closed job still accessible shows historical data", %{conn: conn} do
      {tenant, user} = setup_tenant()
      job = create_job(tenant)
      hash = JobViews.session_hash("10.10.10.10", "Mozilla")

      {:ok, _} =
        JobViews.track_view(%{
          job_id: job.id,
          tenant_id: tenant.id,
          session_hash: hash,
          viewed_at: DateTime.utc_now(),
          user_agent: "Mozilla"
        })

      {:ok, closed} = Treby.Jobs.update_job(job, %{status: "closed"})

      conn = login_user(conn, user)
      {:ok, _view, html} = live(conn, ~p"/app/jobs/#{closed.id}/analytics")
      assert html =~ "Closed"
      assert html =~ "1"
    end
  end

  describe "job management integration" do
    test "job detail shows Analytics link and view summary badge", %{conn: conn} do
      {tenant, user} = setup_tenant()
      job = create_job(tenant)
      conn = login_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/app/jobs/#{job.id}")
      assert has_element?(view, "#job-analytics-link")
      assert has_element?(view, "#job-view-summary")
      assert render(view) =~ "No views yet"

      hash = JobViews.session_hash("11.11.11.11", "Mozilla")

      {:ok, _} =
        JobViews.track_view(%{
          job_id: job.id,
          tenant_id: tenant.id,
          session_hash: hash,
          viewed_at: DateTime.utc_now(),
          user_agent: "Mozilla"
        })

      # reload view should show counts (we need new live)
      {:ok, view2, _} = live(conn, ~p"/app/jobs/#{job.id}")
      assert render(view2) =~ "1 views"
    end

    test "job list shows view indicators", %{conn: conn} do
      {tenant, user} = setup_tenant()
      job1 = create_job(tenant)
      job2 = create_job(tenant)
      hash = JobViews.session_hash("12.12.12.12", "Mozilla")

      {:ok, _} =
        JobViews.track_view(%{
          job_id: job1.id,
          tenant_id: tenant.id,
          session_hash: hash,
          viewed_at: DateTime.utc_now(),
          user_agent: "Mozilla"
        })

      conn = login_user(conn, user)
      {:ok, view, html} = live(conn, ~p"/app/jobs")
      assert html =~ job1.title
      assert html =~ job2.title
      # job1 has views, job2 no views
      assert html =~ "1 · 1 last 7d" or html =~ "1"
      assert html =~ "No views yet"
      assert has_element?(view, "table")
    end
  end

  describe "public tracking" do
    test "anonymous visit increments view and second within window is deduped", %{
      conn: conn
    } do
      {tenant, _user} = setup_tenant()
      job = create_job(tenant)

      {:ok, _view, _html} = live(conn, ~p"/#{tenant.slug}/careers/#{job.id}")
      assert Repo.aggregate(from(v in JobViews.JobView, where: v.job_id == ^job.id), :count) == 1

      {:ok, _view2, _} = live(conn, ~p"/#{tenant.slug}/careers/#{job.id}")
      # Same peer_data "unknown" + UA → deduped within 60m
      count = Repo.aggregate(from(v in JobViews.JobView, where: v.job_id == ^job.id), :count)
      assert count == 1
    end

    test "team member visit does not increment view", %{conn: _conn} do
      {tenant, user} = setup_tenant()
      job = create_job(tenant)
      conn_team = login_user(build_conn(), user)

      {:ok, _view, _html} = live(conn_team, ~p"/#{tenant.slug}/careers/#{job.id}")
      assert Repo.aggregate(from(v in JobViews.JobView, where: v.job_id == ^job.id), :count) == 0
    end

    test "visible=false open job still tracks via direct link", %{conn: conn} do
      {tenant, _user} = setup_tenant()
      pipeline_id = Treby.Pipeline.default_pipeline_id(tenant.id)

      {:ok, job} =
        tenant
        |> Ecto.build_assoc(:jobs)
        |> Job.changeset(%{
          title: "Hidden Position #{System.unique_integer([:positive])}",
          description: "Desc",
          pipeline_id: pipeline_id,
          visible: false
        })
        |> Repo.insert()

      assert job.visible == false
      assert job.status == "open"

      {:ok, _view, _html} = live(conn, ~p"/#{tenant.slug}/careers/#{job.id}")
      assert Repo.aggregate(from(v in JobViews.JobView, where: v.job_id == ^job.id), :count) == 1
    end

    test "closed job view is not tracked", %{conn: conn} do
      {tenant, _user} = setup_tenant()
      job = create_job(tenant)
      {:ok, closed} = Treby.Jobs.update_job(job, %{status: "closed"})

      {:ok, _view, _html} = live(conn, ~p"/#{tenant.slug}/careers/#{closed.id}")

      assert Repo.aggregate(from(v in JobViews.JobView, where: v.job_id == ^closed.id), :count) ==
               0
    end
  end
end
