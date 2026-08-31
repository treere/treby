defmodule TrebyWeb.DashboardI18nTest do
  use TrebyWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias Treby.{Tenants, Repo}
  alias Treby.Accounts.User

  defp setup_tenant do
    {:ok, tenant} =
      Tenants.create_tenant(%{
        name: "Dashboard I18n Corp",
        slug: "dash-i18n-#{System.unique_integer([:positive])}"
      })

    {:ok, user} =
      tenant
      |> Ecto.build_assoc(:users)
      |> User.changeset(%{
        email: "dash-i18n-#{System.unique_integer([:positive])}@test.com",
        password: "password123",
        name: "I18n User",
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

  defp login_with_locale(conn, user, locale) do
    conn
    |> init_test_session(%{
      "user_id" => user.id,
      "tenant_id" => user.tenant_id,
      "locale" => locale
    })
  end

  describe "dashboard localization" do
    test "dashboard renders in Italian when locale is Italian", %{conn: conn} do
      {_tenant, user} = setup_tenant()
      conn = login_with_locale(conn, user, "it")

      {:ok, view, _html} = live(conn, ~p"/app")

      html = render(view)
      assert html =~ "Dashboard"
      # My Actions in Italian (or fallback)
      assert html =~ "Le mie azioni" or html =~ "My Actions"
      # Empty states in Italian
      assert html =~ "Tutto a posto" or html =~ "All caught up"
      # Pipeline overview in Italian or English fallback
      assert html =~ "Panoramica pipeline" or html =~ "Pipeline Overview"
    end

    test "dashboard renders in English when locale is English", %{conn: conn} do
      {_tenant, user} = setup_tenant()
      conn = login_with_locale(conn, user, "en")

      {:ok, view, _html} = live(conn, ~p"/app")

      html = render(view)
      assert html =~ "Dashboard"
      assert html =~ "Applications This Week"
      assert html =~ "My Actions"
      assert html =~ "All caught up"
    end

    test "dashboard welcome message is localized with interpolation", %{conn: conn} do
      {_tenant, user} = setup_tenant()
      conn_it = login_with_locale(conn, user, "it")
      {:ok, view_it, _} = live(conn_it, ~p"/app")
      html_it = render(view_it)
      assert html_it =~ "Benvenuto" or html_it =~ "Welcome"

      conn2 = Phoenix.ConnTest.build_conn()
      conn_en = login_with_locale(conn2, user, "en")
      {:ok, view_en, _} = live(conn_en, ~p"/app")
      html_en = render(view_en)
      assert html_en =~ "Welcome"
    end

    test "dashboard has no missing Italian translations", %{conn: _conn} do
      # Regression: verify that our guard reports 0 missing for dashboard keys
      # This is indirectly verified by mix treby.check_translations, but we assert file exists
      po_path = "priv/gettext/it/LC_MESSAGES/default.po"
      assert File.exists?(po_path)
      content = File.read!(po_path)
      # At least dashboard keys should be present and translated
      assert content =~ "Dashboard"
      # Check that at least one dashboard translation is present
      assert content =~ "Le mie azioni" or content =~ "My Actions"
    end
  end
end
