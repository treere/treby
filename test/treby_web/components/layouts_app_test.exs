defmodule TrebyWeb.LayoutsAppTest do
  use TrebyWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias Treby.{Tenants, Repo}
  alias Treby.Accounts.User

  defp setup_tenant do
    {:ok, tenant} =
      Tenants.create_tenant(%{
        name: "Nav Test Corp",
        slug: "nav-test-#{System.unique_integer([:positive])}"
      })

    {:ok, user} =
      tenant
      |> Ecto.build_assoc(:users)
      |> User.changeset(%{
        email: "nav-#{System.unique_integer([:positive])}@test.com",
        password: "password123",
        name: "Nav User",
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

  describe "responsive app navigation" do
    test "inline links show at xl, hamburger below xl, drawer has all links + close handler", %{
      conn: conn
    } do
      {tenant, user} = setup_tenant()
      conn = login_user(conn, user)
      {:ok, _view, html} = live(conn, "/#{tenant.slug}/app/candidates")

      # Hamburger button is in the bar and hidden at xl (shown below xl)
      assert html =~ ~s(aria-label="Toggle navigation")
      assert html =~ ~s(xl:hidden)

      # Inline links group uses xl breakpoint (not sm) and tightened spacing
      assert html =~ ~s(xl:flex xl:space-x-6)
      refute html =~ ~s(sm:flex sm:space-x-8)

      # Drawer + overlay gate on xl too
      assert html =~ ~s(id="mobile-nav-drawer")
      assert html =~ ~s(id="mobile-nav-overlay")

      # Nav links are tenant-scoped (current_tenant reaches the layout)
      assert html =~ ~s(href="/#{tenant.slug}/app/jobs")
      assert html =~ ~s(href="/#{tenant.slug}/app/candidates")

      # Trimmed primary links (Import and Message Queue moved)
      assert html =~ ~s(data-nav="/app/jobs")
      assert html =~ ~s(data-nav="/app/candidates")
      assert html =~ ~s(data-nav="/app/interviews")
      assert html =~ ~s(data-nav="/app/analytics")
      assert html =~ ~s(data-nav="/app/ai")
      refute html =~ ~s(data-nav="/app/import")
      refute html =~ ~s(data-nav="/app/messages-queue")
      # Settings is now a gear icon, still with data-nav
      assert html =~ ~s(data-nav="/app/settings")
      assert html =~ ~s(aria-label="Settings")
      assert html =~ ~s(hero-cog-6-tooth)

      # Unified user menu replaces scattered controls
      assert html =~ ~s(id="user-menu")
      assert html =~ ~s(id="user-menu-dropdown")

      # Drawer links carry the close-on-tap handler
      assert html =~ "mobile-nav-link"
      assert html =~ "phx-click"
      assert html =~ "#mobile-nav-overlay"
      assert html =~ "#mobile-nav-drawer"
    end

    test "data tables are wrapped in a horizontal scroll container", %{conn: conn} do
      {tenant, user} = setup_tenant()
      conn = login_user(conn, user)
      {:ok, _view, html} = live(conn, "/#{tenant.slug}/app/candidates")
      # Candidate table card switched from overflow-hidden to overflow-x-auto
      assert html =~ "shadow-sm overflow-x-auto"
      assert html =~ "<table"
      assert html =~ "overflow-x-auto"
    end
  end
end
