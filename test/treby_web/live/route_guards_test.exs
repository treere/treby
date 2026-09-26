defmodule TrebyWeb.RouteGuardsTest do
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

  @admin_pages ~w(pipeline fields team webhooks branding company-availability scorecards emails notifications audit-log)

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

  test "recruiter blocked on admin settings by default", %{conn: conn} do
    {tenant, recruiter} = tenant_with("recruiter")
    conn = init_test_session(conn, %{"user_id" => recruiter.id})

    assert {:error, {:redirect, _}} = live(conn, "/#{tenant.slug}/app/settings/team")
    assert {:error, {:redirect, _}} = live(conn, "/#{tenant.slug}/app/settings/audit-log")
  end

  test "recruiter with granted pipeline permission passes pipeline page", %{conn: conn} do
    {tenant, recruiter} = tenant_with("recruiter")
    membership = Memberships.get_membership(recruiter.id, tenant.id)

    {:ok, _} =
      Treby.Authorization.set_override(tenant.id, "recruiter", :pipeline_manage, true, %{
        id: recruiter.id,
        role: membership.role
      })

    conn = init_test_session(conn, %{"user_id" => recruiter.id})
    assert {:ok, _view, html} = live(conn, "/#{tenant.slug}/app/settings/pipeline")
    assert html =~ "Pipeline"
  end

  test "interviewer blocked on team page but allowed on data-privacy", %{conn: conn} do
    {tenant, interviewer} = tenant_with("interviewer")
    conn = init_test_session(conn, %{"user_id" => interviewer.id})

    assert {:error, {:redirect, _}} = live(conn, "/#{tenant.slug}/app/settings/team")
    assert {:ok, _view, html} = live(conn, "/#{tenant.slug}/app/settings/data-privacy")
    assert html =~ "Data"
  end

  test "member allowed on data-privacy (own data scope)", %{conn: conn} do
    {tenant, member} = tenant_with("member")
    conn = init_test_session(conn, %{"user_id" => member.id})
    assert {:ok, _view, html} = live(conn, "/#{tenant.slug}/app/settings/data-privacy")
    assert html =~ "Data"
  end

  test "admin passes on team page", %{conn: conn} do
    {tenant, admin} = tenant_with("admin")
    conn = init_test_session(conn, %{"user_id" => admin.id})
    {:ok, _view, html} = live(conn, "/#{tenant.slug}/app/settings/team")
    assert html =~ "Team"
  end

  test "anonymous visitor redirected to login", %{conn: conn} do
    {tenant, _} = tenant_with("member")
    assert {:error, {:redirect, %{to: to}}} = live(conn, "/#{tenant.slug}/app/settings/team")
    assert to =~ "/login"
  end

  test "legacy /app admin blocked for member", %{conn: conn} do
    {tenant, member} = tenant_with("member")
    conn = init_test_session(conn, %{"user_id" => member.id, "tenant_id" => tenant.id})
    assert {:error, {:redirect, _}} = live(conn, "/app/settings/team")
  end
end
