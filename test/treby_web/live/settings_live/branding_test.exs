defmodule TrebyWeb.SettingsLive.BrandingTest do
  use TrebyWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias Treby.{Tenants, Repo}
  alias Treby.Accounts.User

  defp setup_tenant do
    {:ok, tenant} =
      Tenants.create_tenant(%{
        name: "Branding Test Corp",
        slug: "branding-test-#{System.unique_integer([:positive])}"
      })

    {:ok, user} =
      tenant
      |> Ecto.build_assoc(:users)
      |> User.changeset(%{
        email: "brand-#{System.unique_integer([:positive])}@test.com",
        password: "password123",
        name: "Brand User",
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

  describe "brand settings form" do
    test "has no logo, color, or published controls", %{conn: conn} do
      {_tenant, user} = setup_tenant()
      conn = login_user(conn, user)

      {:ok, _view, html} = live(conn, ~p"/app/settings/branding")

      assert html =~ "About"
      refute html =~ ">Logo<"
      refute html =~ ~s(type="file")
      refute html =~ "Primary Color"
      refute html =~ "Published"
    end

    test "saves about and shows it rendered in the preview tab", %{conn: conn} do
      {_tenant, user} = setup_tenant()
      conn = login_user(conn, user)

      {:ok, view, _html} = live(conn, ~p"/app/settings/branding")

      view
      |> form("#branding-form", %{
        "career_page" => %{
          "title" => "Join Us",
          "description" => "Great tagline",
          "about" => "# Our Story\n\n- one\n- two"
        }
      })
      |> render_change()

      html = view |> element("button", "Preview") |> render_click()

      assert html =~ "Join Us"
      assert html =~ "Great tagline"
      assert html =~ "Our Story"
      assert html =~ "<ul>"

      view |> element("button", "Edit") |> render_click()

      html = view |> form("#branding-form") |> render_submit()

      assert html =~ "Branding saved"
    end
  end
end
