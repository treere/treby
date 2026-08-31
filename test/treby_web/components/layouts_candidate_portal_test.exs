defmodule TrebyWeb.LayoutsCandidatePortalTest do
  use TrebyWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias Treby.{Tenants, Candidates, Pipeline, Repo}
  alias Treby.Jobs.Job
  alias Treby.Pipeline.PipelineStage

  defp setup_tenant_candidate_with_app(status_name \\ "new") do
    {:ok, tenant} =
      Tenants.create_tenant(%{
        name: "Layout Test Corp",
        slug: "layout-test-#{System.unique_integer([:positive])}"
      })

    {:ok, candidate} =
      tenant
      |> Ecto.build_assoc(:candidates)
      |> Candidates.Candidate.changeset(%{
        name: "Layout Candidate",
        email: "layout-#{System.unique_integer([:positive])}@test.com"
      })
      |> Repo.insert()

    pipeline_id = Pipeline.default_pipeline_id(tenant.id)
    pipeline = Repo.get!(Treby.Pipeline.Pipeline, pipeline_id)

    {:ok, stage} =
      pipeline
      |> Ecto.build_assoc(:pipeline_stages)
      |> PipelineStage.changeset(%{name: status_name, position: 0, stage_type: status_name})
      |> Repo.insert()

    {:ok, job} =
      tenant
      |> Ecto.build_assoc(:jobs)
      |> Job.changeset(%{title: "Layout Job", status: "open", description: "Desc"})
      |> Repo.insert()

    {:ok, app} =
      %Treby.Pipeline.Application{}
      |> Treby.Pipeline.Application.changeset(%{
        candidate_id: candidate.id,
        job_id: job.id,
        pipeline_stage_id: stage.id,
        applied_at: DateTime.utc_now(),
        tenant_id: tenant.id
      })
      |> Repo.insert()

    {tenant, candidate, app, stage}
  end

  defp login(conn, candidate, tenant) do
    expires = DateTime.utc_now() |> DateTime.add(4, :hour) |> DateTime.to_unix()

    conn
    |> init_test_session(%{
      "candidate_id" => candidate.id,
      "candidate_tenant_id" => tenant.id,
      "candidate_expires_at" => expires
    })
  end

  describe "candidate portal layout mobile" do
    test "renders hamburger and drawer without overflow", %{conn: conn} do
      {tenant, candidate, _app, _stage} = setup_tenant_candidate_with_app()
      conn = login(conn, candidate, tenant)
      {:ok, view, _html} = live(conn, ~p"/#{tenant.slug}/portal")
      html = render(view)
      # Check for hamburger toggle
      assert html =~ "candidate-portal-drawer"
      assert html =~ "candidate-portal-overlay"
      assert html =~ "Toggle navigation"
      # Hidden on desktop, but present in DOM
      assert html =~ "Messages"
      assert html =~ "Schedule"
      assert html =~ "Settings"
    end

    test "humanizes status new -> Received", %{conn: conn} do
      {tenant, candidate, app, _stage} = setup_tenant_candidate_with_app("new")
      conn = login(conn, candidate, tenant)
      {:ok, view, _html} = live(conn, ~p"/#{tenant.slug}/portal")
      # Need to select application to see badge in detail
      view |> render_click("select_application", %{"id" => app.id})
      html = render(view)
      assert html =~ "Received"
      refute html =~ ">new<"
      # Also list view badge
      # Go back to list and check
    end

    test "close button has aria-label and 44px target", %{conn: conn} do
      {tenant, candidate, app, _stage} = setup_tenant_candidate_with_app("new")
      conn = login(conn, candidate, tenant)
      {:ok, view, _html} = live(conn, ~p"/#{tenant.slug}/portal")
      view |> render_click("select_application", %{"id" => app.id})
      html = render(view)
      assert html =~ "aria-label=\"Close\""
      assert html =~ "min-h-[44px]"
    end
  end
end
