defmodule TrebyWeb.NotFoundTest do
  use TrebyWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias Treby.{Tenants, Repo, Pipeline}
  alias Treby.Accounts.User
  alias Treby.Jobs.Job

  defp setup_tenant do
    {:ok, tenant} =
      Tenants.create_tenant(%{
        name: "Not Found Corp",
        slug: "not-found-#{System.unique_integer([:positive])}"
      })

    {:ok, user} =
      tenant
      |> Ecto.build_assoc(:users)
      |> User.changeset(%{
        email: "notfound-#{System.unique_integer([:positive])}@test.com",
        password: "password123",
        name: "Not Found User",
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

  defp fake_uuid, do: Ecto.UUID.generate()

  describe "not found page" do
    test "renders the 404 page at /404", %{conn: conn} do
      {tenant, user} = setup_tenant()

      conn = conn |> login_user(user)

      {:ok, view, html} = live(conn, ~p"/404")

      assert html =~ "404"
      assert has_element?(view, "a", "Back to Jobs")
      _ = tenant
    end
  end

  describe "non-existent entities redirect to 404" do
    test "non-existent job redirects to /404", %{conn: conn} do
      {tenant, user} = setup_tenant()
      conn = login_user(conn, user)

      {:error, {:redirect, %{to: "/404"}}} = live(conn, ~p"/app/jobs/#{fake_uuid()}")
      _ = tenant
    end

    test "non-existent candidate redirects to /404", %{conn: conn} do
      {tenant, user} = setup_tenant()
      conn = login_user(conn, user)

      {:error, {:redirect, %{to: "/404"}}} = live(conn, ~p"/app/candidates/#{fake_uuid()}")
      _ = tenant
    end

    test "non-existent application in schedule redirects to /404", %{conn: conn} do
      {tenant, user} = setup_tenant()
      conn = login_user(conn, user)

      {:error, {:redirect, %{to: "/404"}}} = live(conn, ~p"/app/schedule/#{fake_uuid()}")
      _ = tenant
    end

    test "non-existent job in pipeline redirects to /404", %{conn: conn} do
      {tenant, user} = setup_tenant()
      conn = login_user(conn, user)

      {:error, {:redirect, %{to: "/404"}}} = live(conn, ~p"/app/pipeline/#{fake_uuid()}")
      _ = tenant
    end
  end

  describe "existing entities still render" do
    test "existing job renders without redirect to /404", %{conn: conn} do
      {tenant, user} = setup_tenant()
      default_id = Pipeline.default_pipeline_id(tenant.id)
      job = create_job(tenant, default_id)
      conn = login_user(conn, user)

      {:ok, _view, html} = live(conn, ~p"/app/jobs/#{job.id}")

      assert html =~ job.title
    end
  end

  describe "non-existent settings entity redirects to 404" do
    test "non-existent pipeline in settings redirects to /404", %{conn: conn} do
      {tenant, user} = setup_tenant()
      conn = login_user(conn, user)

      {:error, {:redirect, %{to: "/404"}}} =
        live(conn, ~p"/app/settings/pipeline/#{fake_uuid()}")

      _ = tenant
    end
  end

  describe "non-existent public entity redirects to 404" do
    test "non-existent public job in careers redirects to /404", %{conn: conn} do
      {tenant, _user} = setup_tenant()

      {:error, {:redirect, %{to: "/404"}}} =
        live(conn, ~p"/#{tenant.slug}/careers/#{fake_uuid()}")
    end

    test "non-existent public job on apply page redirects to /404", %{conn: conn} do
      {tenant, _user} = setup_tenant()

      {:error, {:redirect, %{to: "/404"}}} =
        live(conn, ~p"/#{tenant.slug}/careers/#{fake_uuid()}/apply")
    end
  end
end
