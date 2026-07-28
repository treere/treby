defmodule TrebyWeb.JobsLive.IndexTest do
  use TrebyWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias Treby.{Tenants, Repo}
  alias Treby.Accounts.User

  defp setup_tenant do
    {:ok, tenant} =
      Tenants.create_tenant(%{
        name: "Jobs Test Corp",
        slug: "jobs-test-#{System.unique_integer([:positive])}"
      })

    {:ok, user} =
      tenant
      |> Ecto.build_assoc(:users)
      |> User.changeset(%{
        email: "jobs-#{System.unique_integer([:positive])}@test.com",
        password: "password123",
        name: "Jobs User",
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
    test "shows empty state when no jobs exist", %{conn: conn} do
      {_tenant, user} = setup_tenant()
      conn = login_user(conn, user)

      {:ok, view, _html} = live(conn, ~p"/app/jobs")

      html = render(view)
      assert html =~ "No job postings yet"
      assert html =~ "Create your first job"
    end

    test "hides empty state when jobs exist", %{conn: conn} do
      {tenant, user} = setup_tenant()

      pipeline_id = Treby.Pipeline.default_pipeline_id(tenant.id)

      {:ok, _job} =
        tenant
        |> Ecto.build_assoc(:jobs)
        |> Treby.Jobs.Job.changeset(%{
          title: "Software Engineer",
          description: "Build things",
          pipeline_id: pipeline_id
        })
        |> Repo.insert()

      conn = login_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/app/jobs")

      html = render(view)
      refute html =~ "No job postings yet"
      assert html =~ "Software Engineer"
    end
  end

  describe "form validation" do
    test "shows flash error when creating job with empty title", %{conn: conn} do
      {_tenant, user} = setup_tenant()
      conn = login_user(conn, user)

      {:ok, view, _html} = live(conn, ~p"/app/jobs")

      view
      |> element("button", "New Job")
      |> render_click()

      html =
        view
        |> form("#job-form", %{
          "job" => %{
            "title" => "",
            "description" => "Build amazing things"
          }
        })
        |> render_submit()

      assert html =~ "Please review the errors below"
    end
  end
end
