defmodule TrebyWeb.SettingsWebhooksLiveTest do
  use TrebyWeb.ConnCase, async: false

  import Phoenix.LiveViewTest
  alias Treby.{Tenants, Repo}
  alias Treby.Accounts.User

  defp setup_tenant do
    {:ok, tenant} =
      Tenants.create_tenant(%{
        name: "WH Live #{System.unique_integer([:positive])}",
        slug: "wh-live-#{System.unique_integer([:positive])}"
      })

    tenant
  end

  defp create_user(tenant, role) do
    {:ok, user} =
      tenant
      |> Ecto.build_assoc(:users)
      |> User.changeset(%{
        email: "wh-live-#{System.unique_integer([:positive])}@test.com",
        password: "password123",
        name: "WH User",
        role: role
      })
      |> Repo.insert()

    {:ok, _} =
      Treby.Memberships.create_membership(%{
        user_id: user.id,
        tenant_id: tenant.id,
        role: role
      })

    user
  end

  defp with_session(conn, user, tenant) do
    conn
    |> init_test_session(%{"user_id" => user.id, "tenant_id" => tenant.id, "locale" => "en"})
  end

  test "admin can view the webhooks settings page", %{conn: conn} do
    tenant = setup_tenant()
    admin = create_user(tenant, "admin")
    conn = with_session(conn, admin, tenant)

    {:ok, _view, html} = live(conn, "/#{tenant.slug}/app/settings/webhooks")

    assert html =~ "Webhooks"
    assert html =~ "New Webhook"
  end

  test "member is redirected away from the webhooks settings page", %{conn: conn} do
    tenant = setup_tenant()
    member = create_user(tenant, "member")
    conn = with_session(conn, member, tenant)

    conn = get(conn, "/#{tenant.slug}/app/settings/webhooks")

    assert redirected_to(conn) == "/#{tenant.slug}/app"
  end

  test "admin can create a webhook subscription via the form", %{conn: conn} do
    tenant = setup_tenant()
    admin = create_user(tenant, "admin")
    conn = with_session(conn, admin, tenant)

    {:ok, view, _html} = live(conn, "/#{tenant.slug}/app/settings/webhooks")

    view |> element("button", "New Webhook") |> render_click()

    html =
      view
      |> element("#webhook-form")
      |> render_submit(%{
        webhook_subscription: %{
          target_url: "https://example.com/hook",
          events_text: "candidate.*",
          description: "regression test"
        }
      })

    assert html =~ "https://example.com/hook"
    assert html =~ "candidate.*"
  end
end
