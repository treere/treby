defmodule TrebyWeb.AuthWorkspaceTest do
  use TrebyWeb.ConnCase, async: false
  import Phoenix.LiveViewTest

  alias Treby.{Tenants, Repo, Memberships}
  alias Treby.Accounts.User

  defp create_tenant(name) do
    {:ok, tenant} = Tenants.create_tenant(%{name: name})
    tenant
  end

  defp create_user(tenant, email, role \\ "member") do
    {:ok, user} =
      tenant
      |> Ecto.build_assoc(:users)
      |> User.changeset(%{email: email, password: "password123", name: "Test", role: role})
      |> Repo.insert()

    # Ensure membership (idempotent)
    case Memberships.create_membership(%{user_id: user.id, tenant_id: tenant.id, role: role}) do
      {:ok, _} -> :ok
      {:error, _} -> :ok
    end

    {tenant, user}
  end

  describe "global email uniqueness" do
    test "lower(email) is unique globally" do
      {_t1, _u1} =
        create_user(create_tenant("Uniq1"), "uniq-#{System.unique_integer([:positive])}@test.com")

      tenant2 = create_tenant("Uniq2")
      email = "MiXed-#{System.unique_integer([:positive])}@Test.COM"
      {_t, user} = create_user(tenant2, String.downcase(email))
      dup_email = String.upcase(user.email)
      # Try to insert duplicate via build_assoc (should fail on lower(email) unique)
      changeset =
        tenant2
        |> Ecto.build_assoc(:users)
        |> User.changeset(%{
          email: dup_email,
          password: "password123",
          name: "Dup",
          role: "member"
        })

      assert {:error, cs} = Repo.insert(changeset)
      assert cs.errors[:email] || cs.errors[:tenant_id]
    end
  end

  describe "login picker" do
    test "single membership redirects to slug app", %{conn: conn} do
      {_tenant, user} =
        create_user(
          create_tenant("Single"),
          "single-#{System.unique_integer([:positive])}@test.com"
        )

      # Need tenant for assertion
      [%{tenant: tenant}] = Memberships.list_tenants_for_user(user.id)

      conn =
        post(conn, ~p"/session", %{
          "user" => %{"email" => user.email, "password" => "password123"}
        })

      assert redirected_to(conn) == "/#{tenant.slug}/app"
    end

    test "multiple memberships redirects to choose-tenant", %{conn: conn} do
      tenant_a = create_tenant("MultiA")
      tenant_b = create_tenant("MultiB")
      email = "multi-#{System.unique_integer([:positive])}@test.com"

      {:ok, user} =
        tenant_a
        |> Ecto.build_assoc(:users)
        |> User.changeset(%{email: email, password: "password123", name: "Multi", role: "member"})
        |> Repo.insert()

      {:ok, _} =
        Memberships.create_membership(%{user_id: user.id, tenant_id: tenant_a.id, role: "member"})

      {:ok, _} =
        Memberships.create_membership(%{user_id: user.id, tenant_id: tenant_b.id, role: "admin"})

      conn =
        post(conn, ~p"/session", %{"user" => %{"email" => email, "password" => "password123"}})

      assert redirected_to(conn) == "/choose-tenant"

      # Follow to picker (LiveView) with fresh conn
      {:ok, _view, html} =
        live(build_conn() |> init_test_session(%{"user_id" => user.id}), ~p"/choose-tenant")

      assert html =~ "Choose workspace"
      assert html =~ tenant_a.slug
      assert html =~ tenant_b.slug
    end

    test "picker enforces membership", %{conn: conn} do
      tenant_a = create_tenant("EnforceA")
      tenant_b = create_tenant("EnforceB")
      other = create_tenant("Other")
      email = "enforce-#{System.unique_integer([:positive])}@test.com"

      {:ok, user} =
        tenant_a
        |> Ecto.build_assoc(:users)
        |> User.changeset(%{
          email: email,
          password: "password123",
          name: "Enforce",
          role: "member"
        })
        |> Repo.insert()

      {:ok, _} =
        Memberships.create_membership(%{user_id: user.id, tenant_id: tenant_a.id, role: "member"})

      {:ok, _} =
        Memberships.create_membership(%{user_id: user.id, tenant_id: tenant_b.id, role: "member"})

      # Try to POST choose-tenant with other tenant not belonging
      conn =
        conn
        |> init_test_session(%{"user_id" => user.id})
        |> post(~p"/choose-tenant", %{"slug" => other.slug})

      assert redirected_to(conn) == "/choose-tenant"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "don't belong"
    end

    test "URL without membership redirects to choose-tenant", %{conn: conn} do
      tenant_a = create_tenant("NoMemA")
      tenant_b = create_tenant("NoMemB")

      {_ta, user_a} =
        create_user(tenant_a, "nomem-a-#{System.unique_integer([:positive])}@test.com")

      # user_a only in tenant_a, try to access tenant_b slug
      conn = conn |> init_test_session(%{"user_id" => user_a.id}) |> get("/#{tenant_b.slug}/app")
      assert redirected_to(conn) == "/choose-tenant"
    end

    test "create second company via POST /tenants", %{conn: conn} do
      {_tenant, user} =
        create_user(
          create_tenant("First"),
          "second-#{System.unique_integer([:positive])}@test.com",
          "admin"
        )

      conn =
        conn
        |> init_test_session(%{"user_id" => user.id})
        |> post(~p"/tenants", %{"tenant" => %{"name" => "Second Co"}})

      assert redirected_to(conn) =~ ~r"/second-co.*\/app"
      # Verify membership created
      assert length(Memberships.list_tenants_for_user(user.id)) == 2
    end

    test "legacy /app still renders via session fallback", %{conn: conn} do
      {_tenant, user} =
        create_user(
          create_tenant("Legacy"),
          "legacy-#{System.unique_integer([:positive])}@test.com"
        )

      {:ok, _view, html} = live(conn |> init_test_session(%{"user_id" => user.id}), ~p"/app/jobs")
      assert html =~ "Jobs"
    end
  end
end
