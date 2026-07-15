defmodule TrebyWeb.TenantIsolationTest do
  use TrebyWeb.ConnCase, async: false

  alias Treby.{Tenants, Jobs, Candidates, Pipeline, Repo}
  alias Treby.Accounts.User

  defp create_tenant_with_user(attrs \\ %{}) do
    tenant_attrs = Map.merge(%{name: "Test Corp", slug: "test-corp"}, attrs[:tenant] || %{})
    {:ok, tenant} = Tenants.create_tenant(tenant_attrs)
    Pipeline.create_default_pipeline_stages(tenant)

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

  describe "tenant isolation" do
    test "users cannot access other tenants' jobs via API" do
      {tenant1, _user1} =
        create_tenant_with_user(%{tenant: %{name: "Tenant One", slug: "tenant-one"}})

      {tenant2, _user2} =
        create_tenant_with_user(%{tenant: %{name: "Tenant Two", slug: "tenant-two"}})

      job =
        tenant2
        |> Ecto.build_assoc(:jobs)
        |> Treby.Jobs.Job.changeset(%{title: "Secret Job", description: "Very secret"})
        |> Repo.insert!()

      assert_raise Ecto.NoResultsError, fn ->
        Jobs.get_job!(tenant1.id, job.id)
      end
    end

    test "users cannot access other tenants' candidates via API" do
      {tenant1, _user1} =
        create_tenant_with_user(%{tenant: %{name: "Tenant One", slug: "tenant-one"}})

      {tenant2, _user2} =
        create_tenant_with_user(%{tenant: %{name: "Tenant Two", slug: "tenant-two"}})

      candidate =
        tenant2
        |> Ecto.build_assoc(:candidates)
        |> Treby.Candidates.Candidate.changeset(%{
          name: "Secret Candidate",
          email: "secret@test.com"
        })
        |> Repo.insert!()

      assert_raise Ecto.NoResultsError, fn ->
        Candidates.get_candidate!(tenant1.id, candidate.id)
      end
    end

    test "unauthenticated user is redirected to login", %{conn: conn} do
      conn = get(conn, ~p"/app")
      assert redirected_to(conn) == "/login"
    end

    test "authenticated user can access their dashboard", %{conn: conn} do
      {_tenant, user} = create_tenant_with_user()

      conn =
        conn
        |> init_test_session(%{
          "user_id" => user.id,
          "tenant_id" => user.tenant_id
        })
        |> get(~p"/app")

      assert html_response(conn, 200)
    end
  end
end
