defmodule TrebyWeb.SettingsLive.NotificationsTest do
  use TrebyWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias Treby.{Tenants, Repo, Notifications}
  alias Treby.Accounts.User

  defp setup_tenant do
    {:ok, tenant} =
      Tenants.create_tenant(%{
        name: "Notifications Test Corp",
        slug: "notifications-test-#{System.unique_integer([:positive])}"
      })

    {:ok, user} =
      tenant
      |> Ecto.build_assoc(:users)
      |> User.changeset(%{
        email: "notif-#{System.unique_integer([:positive])}@test.com",
        password: "password123",
        name: "Notif User",
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

  describe "admin notification toggles" do
    test "flips state in DOM and persists each preference", %{conn: conn} do
      {tenant, user} = setup_tenant()
      conn = login_user(conn, user)

      {:ok, view, _html} = live(conn, ~p"/app/settings/notifications")

      for key <- ["stage_change_candidate", "new_application_candidate", "new_application_team"] do
        assert Notifications.notification_preferences_enabled?(
                 Repo.reload!(tenant),
                 key
               ) == true

        html =
          view
          |> element(
            ~s(button[phx-click="toggle_preference"][phx-value-key="#{key}"][phx-value-channel="email"])
          )
          |> render_click()

        assert html =~ "Notification preference updated"
        assert html =~ ~s(aria-checked="false")

        assert Notifications.notification_preferences_enabled?(
                 Repo.reload!(tenant),
                 key
               ) == false

        html =
          view
          |> element(
            ~s(button[phx-click="toggle_preference"][phx-value-key="#{key}"][phx-value-channel="email"])
          )
          |> render_click()

        assert html =~ ~s(aria-checked="true")

        assert Notifications.notification_preferences_enabled?(
                 Repo.reload!(tenant),
                 key
               ) == true
      end
    end
  end
end
