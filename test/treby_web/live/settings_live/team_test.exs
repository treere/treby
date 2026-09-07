defmodule TrebyWeb.SettingsLive.TeamTest do
  use TrebyWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias Treby.{Tenants, Repo}
  alias Treby.Accounts.User

  defp setup_tenant do
    {:ok, tenant} =
      Tenants.create_tenant(%{
        name: "Team Test Corp",
        slug: "team-test-#{System.unique_integer([:positive])}"
      })

    {:ok, user} =
      tenant
      |> Ecto.build_assoc(:users)
      |> User.changeset(%{
        email: "team-#{System.unique_integer([:positive])}@test.com",
        password: "password123",
        name: "Team User",
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

  defp login_user(conn, user, extra \\ %{}) do
    conn
    |> init_test_session(Map.merge(%{"user_id" => user.id}, extra))
  end

  describe "team page reachability" do
    test "loads on legacy path without tenant_id in session", %{conn: conn} do
      {_tenant, user} = setup_tenant()
      conn = login_user(conn, user)

      {:ok, _view, html} = live(conn, ~p"/app/settings/team")

      assert html =~ "Team Management"
    end

    test "loads on legacy path with tenant_id in session", %{conn: conn} do
      {tenant, user} = setup_tenant()
      conn = login_user(conn, user, %{"tenant_id" => tenant.id})

      {:ok, _view, html} = live(conn, ~p"/app/settings/team")

      assert html =~ "Team Management"
    end

    test "loads on tenant slug path", %{conn: conn} do
      {tenant, user} = setup_tenant()
      conn = login_user(conn, user)

      {:ok, _view, html} = live(conn, ~p"/#{tenant.slug}/app/settings/team")

      assert html =~ "Team Management"
    end
  end
end
