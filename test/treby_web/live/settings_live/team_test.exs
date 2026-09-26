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
      {tenant, user} = setup_tenant()
      conn = login_user(conn, user)

      {:ok, _view, html} = live(conn, "/#{tenant.slug}/app/settings/team")

      assert html =~ "Team Management"
    end

    test "loads on legacy path with tenant_id in session", %{conn: conn} do
      {tenant, user} = setup_tenant()
      conn = login_user(conn, user, %{"tenant_id" => tenant.id})

      {:ok, _view, html} = live(conn, "/#{tenant.slug}/app/settings/team")

      assert html =~ "Team Management"
    end

    test "loads on tenant slug path", %{conn: conn} do
      {tenant, user} = setup_tenant()
      conn = login_user(conn, user)

      {:ok, _view, html} = live(conn, ~p"/#{tenant.slug}/app/settings/team")

      assert html =~ "Team Management"
    end
  end

  describe "roles and permissions matrix" do
    test "admin grants a permission and it persists with audit", %{conn: conn} do
      {tenant, admin} = setup_tenant()
      conn = login_user(conn, admin)

      {:ok, view, html} = live(conn, "/#{tenant.slug}/app/settings/team")

      assert html =~ "Roles &amp; permissions" or html =~ "Roles & permissions"
      assert has_element?(view, "#perm-toggle-recruiter-pipeline_manage")

      view
      |> element("#perm-toggle-recruiter-pipeline_manage")
      |> render_click()

      assert Treby.Authorization.can?(
               Treby.Authorization.effective_for(tenant.id, "recruiter"),
               :pipeline_manage
             )

      assert %Treby.Authorization.RolePermission{} =
               Treby.Repo.get_by(Treby.Authorization.RolePermission,
                 tenant_id: tenant.id,
                 role: "recruiter",
                 action: "pipeline_manage"
               )

      assert %Treby.Audit.AuditEvent{} =
               Treby.Repo.get_by(Treby.Audit.AuditEvent,
                 tenant_id: tenant.id,
                 action: "role_permission.updated"
               )
    end

    test "recruiter cannot toggle permissions", %{conn: conn} do
      {tenant, _admin} = setup_tenant()

      {:ok, recruiter} =
        tenant
        |> Ecto.build_assoc(:users)
        |> User.changeset(%{
          email: "rec-#{System.unique_integer([:positive])}@test.com",
          password: "password123",
          name: "Rec",
          role: "member"
        })
        |> Repo.insert()

      {:ok, _} =
        Treby.Memberships.create_membership(%{
          user_id: recruiter.id,
          tenant_id: tenant.id,
          role: "recruiter"
        })

      conn = login_user(conn, %{recruiter | tenant_id: tenant.id})

      assert {:error, {:redirect, _}} = live(conn, "/#{tenant.slug}/app/settings/team")

      assert {:error, :invalid_role} =
               Treby.Authorization.set_override(tenant.id, "admin", :pipeline_manage, true, nil)

      assert {:error, :locked_action} =
               Treby.Authorization.set_override(tenant.id, "recruiter", :team_manage, true, nil)
    end
  end
end
