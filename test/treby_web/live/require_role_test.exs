defmodule TrebyWeb.RequireRoleTest do
  use TrebyWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias Treby.{Tenants, Repo, Memberships}
  alias Treby.Accounts.User

  defp tenant_with(role) do
    suffix = System.unique_integer([:positive])

    {:ok, tenant} =
      Tenants.create_tenant(%{
        name: "RR #{suffix}",
        slug: "rr-#{suffix}"
      })

    {:ok, user} =
      tenant
      |> Ecto.build_assoc(:users)
      |> User.changeset(%{
        email: "rr-#{suffix}@test.com",
        password: "password123",
        name: "Test",
        role: role
      })
      |> Repo.insert()

    {:ok, _} =
      Memberships.create_membership(%{user_id: user.id, tenant_id: tenant.id, role: role})

    {tenant, user}
  end

  @admin_pages ~w(pipeline fields team webhooks branding company-availability scorecards emails notifications audit-log data-privacy)

  test "member blocked on all admin settings (tenant slug path)", %{conn: conn} do
    {tenant, member} = tenant_with("member")
    conn = init_test_session(conn, %{"user_id" => member.id})

    for page <- @admin_pages do
      path = "/#{tenant.slug}/app/settings/#{page}"

      assert {:error, {:redirect, %{to: to}}} = live(conn, path),
             "expected redirect for member on #{path}, got ok"

      assert to =~ tenant.slug or to =~ "choose-tenant" or to =~ "/app",
             "redirect for #{page} should go to tenant app or picker, got #{to}"
    end
  end

  test "admin passes on team page", %{conn: conn} do
    {tenant, admin} = tenant_with("admin")
    conn = init_test_session(conn, %{"user_id" => admin.id})
    {:ok, _view, html} = live(conn, "/#{tenant.slug}/app/settings/team")
    assert html =~ "Team"
  end

  test "legacy /app admin blocked for member", %{conn: conn} do
    {tenant, member} = tenant_with("member")
    conn = init_test_session(conn, %{"user_id" => member.id, "tenant_id" => tenant.id})
    assert {:error, {:redirect, _}} = live(conn, "/app/settings/team")
  end
end
