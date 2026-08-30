defmodule TrebyWeb.SettingsLive.SourcesTest do
  use TrebyWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias Treby.{Tenants, Repo}
  alias Treby.Accounts.User

  defp setup_tenant do
    {:ok, tenant} =
      Tenants.create_tenant(%{
        name: "Sources Test Corp",
        slug: "sources-test-#{System.unique_integer([:positive])}"
      })

    {:ok, user} =
      tenant
      |> Ecto.build_assoc(:users)
      |> User.changeset(%{
        email: "src-#{System.unique_integer([:positive])}@test.com",
        password: "password123",
        name: "Sources User",
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

  describe "form validation" do
    test "shows flash error when saving source with empty name", %{conn: conn} do
      {_tenant, user} = setup_tenant()
      conn = login_user(conn, user)

      {:ok, view, _html} = live(conn, ~p"/app/settings/sources")

      view
      |> element("button", "Add Source")
      |> render_click()

      html =
        view
        |> form("#source-form", %{
          "source" => %{
            "name" => ""
          }
        })
        |> render_submit()

      assert html =~ "Please review the errors below"
    end
  end
end
