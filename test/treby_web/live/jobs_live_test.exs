defmodule TrebyWeb.JobsLive.IndexTest do
  use TrebyWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias Treby.{Tenants, Repo}
  alias Treby.Accounts.User
  alias Treby.Jobs.Job

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

  describe "empty state" do
    test "shows empty state when no jobs exist", %{conn: conn} do
      {_tenant, user} = setup_tenant()
      conn = login_user(conn, user)

      {:ok, view, _html} = live(conn, ~p"/app/jobs")

      html = render(view)
      assert html =~ "No job postings yet"
      assert html =~ "Create your first job"
      refute has_element?(view, "#job-form")
    end

    test "empty state button navigates to dedicated creation page", %{conn: conn} do
      {_tenant, user} = setup_tenant()
      conn = login_user(conn, user)

      {:ok, view, _html} = live(conn, ~p"/app/jobs")

      assert has_element?(view, ~s(a[href="/app/jobs/new"]))

      {:ok, new_view, _html} = live(conn, ~p"/app/jobs/new")
      assert has_element?(new_view, "#job-create-form")
      assert has_element?(new_view, "#job-preview-card")
    end

    test "listing has no inline creation form", %{conn: conn} do
      {_tenant, user} = setup_tenant()
      conn = login_user(conn, user)

      {:ok, view, _html} = live(conn, ~p"/app/jobs")
      refute has_element?(view, "#job-create-form")
      refute has_element?(view, "#job-form")
      html = render(view)
      refute html =~ ~s(id="job-form")
    end

    test "hides empty state when jobs exist", %{conn: conn} do
      {tenant, user} = setup_tenant()

      pipeline_id = Treby.Pipeline.default_pipeline_id(tenant.id)

      {:ok, _job} =
        tenant
        |> Ecto.build_assoc(:jobs)
        |> Job.changeset(%{
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

  describe "pagination" do
    test "shows pager with result count and navigates pages", %{conn: conn} do
      {tenant, user} = setup_tenant()
      pipeline_id = Treby.Pipeline.default_pipeline_id(tenant.id)

      base = DateTime.utc_now() |> DateTime.truncate(:second)

      for i <- 1..30 do
        # Explicit staggered timestamps: fast inserts share the same second,
        # which would leave newest-first ordering to chance.
        inserted_at = DateTime.add(base, i, :second)

        {:ok, _} =
          tenant
          |> Ecto.build_assoc(:jobs)
          |> Job.changeset(%{
            title: "Paged Job #{String.pad_leading(to_string(i), 2, "0")}",
            description: "Work",
            pipeline_id: pipeline_id
          })
          |> Ecto.Changeset.force_change(:inserted_at, inserted_at)
          |> Ecto.Changeset.force_change(:updated_at, inserted_at)
          |> Repo.insert()
      end

      conn = login_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/app/jobs")

      assert has_element?(view, "#pagination")
      html = render(view)
      assert html =~ "Showing 1–25 of 30"
      assert html =~ "Paged Job 30"
      refute html =~ "Paged Job 01"

      html =
        view
        |> element("#pagination a", "2")
        |> render_click()

      assert html =~ "Showing 26–30 of 30"
      assert html =~ "Paged Job 01"
      refute html =~ "Paged Job 30"
    end
  end

  describe "form validation" do
    test "shows validation error when creating job with empty title on dedicated page", %{
      conn: conn
    } do
      {_tenant, user} = setup_tenant()
      conn = login_user(conn, user)

      {:ok, view, _html} = live(conn, ~p"/app/jobs/new")

      html =
        view
        |> form("#job-create-form", %{
          "job" => %{
            "title" => "",
            "description" => "Build amazing things"
          }
        })
        |> render_submit()

      assert html =~ "Please review the errors below"
    end

    test "New Job button navigates to creation page", %{conn: conn} do
      {_tenant, user} = setup_tenant()
      conn = login_user(conn, user)

      {:ok, view, _html} = live(conn, ~p"/app/jobs")
      assert has_element?(view, ~s(a[href="/app/jobs/new"]))

      {:ok, new_view, html} = live(conn, ~p"/app/jobs/new")
      assert has_element?(new_view, "#job-create-form")
      assert html =~ "Job details"
    end
  end

  describe "copy public link" do
    test "renders an absolute career page URL on the copy button", %{conn: conn} do
      {tenant, user} = setup_tenant()

      pipeline_id = Treby.Pipeline.default_pipeline_id(tenant.id)

      {:ok, job} =
        tenant
        |> Ecto.build_assoc(:jobs)
        |> Job.changeset(%{
          title: "Copy Link Job",
          description: "Share me",
          pipeline_id: pipeline_id
        })
        |> Repo.insert()

      conn = login_user(conn, user)
      {:ok, _view, html} = live(conn, ~p"/app/jobs/#{job.id}")

      expected = TrebyWeb.Endpoint.url() <> "/#{tenant.slug}/careers/#{job.id}"

      assert html =~ ~s{data-url="#{expected}"}
      assert html =~ ~s{id="copy-public-link"}
    end
  end
end
