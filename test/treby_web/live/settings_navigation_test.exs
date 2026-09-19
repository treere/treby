defmodule TrebyWeb.SettingsNavigationTest do
  use TrebyWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias Treby.{Tenants, Repo}
  alias Treby.Accounts.User

  defp setup_tenant(role \\ "admin") do
    {:ok, tenant} =
      Tenants.create_tenant(%{
        name: "Nav Test Corp #{System.unique_integer([:positive])}",
        slug: "nav-test-#{System.unique_integer([:positive])}"
      })

    {:ok, user} =
      tenant
      |> Ecto.build_assoc(:users)
      |> User.changeset(%{
        email: "nav-#{System.unique_integer([:positive])}@test.com",
        password: "password123",
        name: "Nav User",
        role: role
      })
      |> Repo.insert()

    {:ok, _} =
      Treby.Memberships.create_membership(%{
        user_id: user.id,
        tenant_id: tenant.id,
        role: role
      })

    {tenant, %{user | tenant_id: tenant.id}}
  end

  defp login_user(conn, user) do
    conn
    |> init_test_session(%{
      "user_id" => user.id,
      "tenant_id" => user.tenant_id
    })
  end

  describe "settings hub grouping" do
    test "admin sees five groups in fixed order and all items including Message Queue", %{
      conn: conn
    } do
      {_tenant, user} = setup_tenant("admin")
      conn = login_user(conn, user)
      {:ok, _view, html} = live(conn, ~p"/app/settings")

      assert html =~ "Organization"
      assert html =~ "Hiring Process"
      assert html =~ "Communication"
      assert html =~ "Scheduling"
      assert html =~ "Privacy &amp; System" or html =~ "Privacy & System"

      # Admin sees all groups items including Message Queue under Communication
      assert html =~ "Message Queue"
      assert html =~ "Team"
      assert html =~ "Pipeline Stages"
      assert html =~ "Message Templates"
      assert html =~ "Audit Log"

      # Admin badges present
      assert html =~ "Admin"

      # Verify defined order via config, not fragile html index
      groups = TrebyWeb.SettingsNav.groups_for_role("admin") |> Enum.map(& &1.label)

      assert groups == [
               "Organization",
               "Hiring Process",
               "Communication",
               "Scheduling",
               "Privacy & System"
             ]
    end

    test "member sees reduced settings with callout and hidden empty groups", %{conn: conn} do
      {_tenant, user} = setup_tenant("member")
      conn = login_user(conn, user)
      {:ok, _view, html} = live(conn, ~p"/app/settings")

      assert html =~ "Some settings require admin"
      assert html =~ "Calendar"
      assert html =~ "My Availability"
      assert html =~ "Language"

      # Member should not see admin-only items
      refute html =~ "Team"
      refute html =~ "Pipeline Stages"
      refute html =~ "Message Queue"
    end

    test "active item is highlighted with aria-current", %{conn: conn} do
      {_tenant, user} = setup_tenant("admin")
      conn = login_user(conn, user)
      {:ok, _view, html} = live(conn, ~p"/app/settings/pipeline")

      assert html =~ ~s(id="settings-nav-pipeline")
      assert html =~ ~s(aria-current="page")
      assert html =~ "bg-zinc-100"
    end

    test "deep link to webhooks preserves active state", %{conn: conn} do
      {_tenant, user} = setup_tenant("admin")
      conn = login_user(conn, user)
      {:ok, _view, html} = live(conn, ~p"/app/settings/webhooks")

      assert html =~ ~s(id="settings-nav-webhooks")
      assert html =~ ~s(aria-current="page")
    end

    test "message queue renders inside settings shell with active", %{conn: conn} do
      {_tenant, user} = setup_tenant("admin")
      conn = login_user(conn, user)
      {:ok, _view, html} = live(conn, ~p"/app/messages-queue")

      assert html =~ ~s(id="settings-nav-message-queue")
      assert html =~ ~s(aria-current="page")
      assert html =~ "Message Queue" or html =~ "Scheduled"
    end

    test "company availability cross-link under Scheduling", %{conn: conn} do
      {_tenant, user} = setup_tenant("admin")
      conn = login_user(conn, user)
      {:ok, _view, html} = live(conn, ~p"/app/settings/team")

      assert html =~ ~s(id="settings-nav-company-availability-crosslink")
      assert html =~ "Manage company defaults"
    end

    test "sidebar respects tenant slug paths", %{conn: conn} do
      {tenant, user} = setup_tenant("admin")
      conn = login_user(conn, user)
      {:ok, _view, html} = live(conn, "/#{tenant.slug}/app/settings")

      assert html =~ "/#{tenant.slug}/app/settings/team"
      assert html =~ "/#{tenant.slug}/app/messages-queue"
    end

    test "personal settings accessible to member via default session", %{conn: conn} do
      {_tenant, user} = setup_tenant("member")
      conn = login_user(conn, user)

      {:ok, _view, html} = live(conn, ~p"/app/settings/calendar")
      assert html =~ "Calendar" or html =~ "Google Calendar"

      {:ok, _view, html2} = live(conn, ~p"/app/settings/availability")
      assert html2 =~ "Availability" or html2 =~ "available hours"

      {:ok, _view, html3} = live(conn, ~p"/app/settings/language")
      assert html3 =~ "Language"
    end
  end

  describe "top navigation trimmed" do
    test "candidates header shows Import CSV button tenant-aware", %{conn: conn} do
      {tenant, user} = setup_tenant("admin")
      conn = login_user(conn, user)
      {:ok, _view, html} = live(conn, ~p"/app/candidates")

      assert html =~ ~s(id="candidates-import-button")
      assert html =~ "Import CSV"
      assert html =~ "hero-arrow-up-tray"
      # Button links to import
      assert html =~ "/app/import" or html =~ "/#{tenant.slug}/app/import"
    end

    test "gear icon active on settings page", %{conn: conn} do
      {_tenant, user} = setup_tenant("admin")
      conn = login_user(conn, user)
      {:ok, _view, html} = live(conn, ~p"/app/settings")

      assert html =~ ~s(id="settings-gear")
      assert html =~ "hero-cog-6-tooth"
      # When on settings, gear should have active bg
      assert html =~ "bg-zinc-100"
    end
  end
end
