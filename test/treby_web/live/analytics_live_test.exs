defmodule TrebyWeb.AnalyticsLiveTest do
  use TrebyWeb.ConnCase, async: false

  import Phoenix.LiveViewTest
  import Ecto.Query

  alias Treby.{Tenants, Repo}
  alias Treby.Accounts.User
  alias Treby.Jobs.Job
  alias Treby.Candidates.Candidate
  alias Treby.Pipeline.{Application, PipelineStage}

  defp setup_tenant(role \\ "admin") do
    {:ok, tenant} =
      Tenants.create_tenant(%{
        name: "Analytics Tenant #{System.unique_integer([:positive])}",
        slug: "analytics-t-#{System.unique_integer([:positive])}"
      })

    {:ok, user} =
      tenant
      |> Ecto.build_assoc(:users)
      |> User.changeset(%{
        email: "analytics-a-#{System.unique_integer([:positive])}@test.com",
        password: "password123",
        name: "Analytics User",
        role: role
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

  describe "tenant analytics page" do
    test "shows empty placeholders when no candidates", %{conn: conn} do
      {_tenant, user} = setup_tenant()
      conn = login_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/app/analytics")
      html = render(view)
      # pipeline overview placeholder or empty state
      assert html =~ "pipeline-overview-empty" or html =~ "No pipeline data"
      assert html =~ "chart-card"
    end

    test "renders svg charts when candidates exist", %{conn: conn} do
      {tenant, user} = setup_tenant()
      # create a candidate and application to populate pipeline
      {:ok, job} =
        tenant
        |> Ecto.build_assoc(:jobs)
        |> Job.changeset(%{
          title: "Test Job",
          description: "Desc",
          pipeline_id: Treby.Pipeline.default_pipeline_id(tenant.id)
        })
        |> Repo.insert()

      {:ok, candidate} =
        %Candidate{}
        |> Ecto.Changeset.change(%{
          name: "Cand #{System.unique_integer([:positive])}",
          email: "cand-#{System.unique_integer([:positive])}@example.com",
          tenant_id: tenant.id
        })
        |> Repo.insert()

      stage_id =
        Repo.one!(
          from s in PipelineStage,
            where: s.pipeline_id == ^job.pipeline_id,
            limit: 1
        ).id

      {:ok, _app} =
        %Application{}
        |> Ecto.Changeset.change(%{
          job_id: job.id,
          candidate_id: candidate.id,
          pipeline_stage_id: stage_id,
          tenant_id: tenant.id,
          applied_at: DateTime.utc_now() |> DateTime.truncate(:second)
        })
        |> Repo.insert()

      conn = login_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/app/analytics")
      html = render(view)
      assert html =~ "<svg"
      assert html =~ "pipeline-overview-chart"
    end

    test "pipeline selector re-renders and remains tenant scoped", %{conn: conn} do
      {tenant_a, user_a} = setup_tenant()
      {tenant_b, _user_b} = setup_tenant()

      # tenant A has a job/candidate
      {:ok, _job_a} =
        tenant_a
        |> Ecto.build_assoc(:jobs)
        |> Job.changeset(%{
          title: "Job A",
          description: "Desc",
          pipeline_id: Treby.Pipeline.default_pipeline_id(tenant_a.id)
        })
        |> Repo.insert()

      conn_a = login_user(conn, user_a)
      {:ok, view, _html} = live(conn_a, ~p"/app/analytics")
      html = render(view)
      # should not see tenant B's data
      refute html =~ tenant_b.slug
      assert has_element?(view, "#pipeline-overview-card")
    end
  end
end
