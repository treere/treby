defmodule TrebyWeb.SettingsLive.AvailabilityTest do
  use TrebyWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias Treby.{Tenants, Repo, Availability}
  alias Treby.Accounts.User

  defp setup_user(role) do
    {:ok, tenant} =
      Tenants.create_tenant(%{
        name: "Availability Test Corp",
        slug: "availability-test-#{System.unique_integer([:positive])}"
      })

    {:ok, user} =
      tenant
      |> Ecto.build_assoc(:users)
      |> User.changeset(%{
        email: "availability-#{System.unique_integer([:positive])}@test.com",
        password: "password123",
        name: "Availability User",
        role: role
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

  defp login(conn, user) do
    init_test_session(conn, %{"user_id" => user.id, "tenant_id" => user.tenant_id})
  end

  describe "user availability page" do
    test "renders the page and shows existing rules", %{conn: conn} do
      {tenant, user} = setup_user("admin")

      Availability.create_rule(%{
        user_id: user.id,
        tenant_id: tenant.id,
        day_of_week: 1,
        start_time: ~T[09:00:00],
        end_time: ~T[17:00:00]
      })

      {:ok, _view, html} = live(conn |> login(user), ~p"/app/settings/availability")

      assert html =~ "Availability"
      assert html =~ "Monday"
      assert html =~ "09:00"
    end

    test "adds a new availability rule", %{conn: conn} do
      {_tenant, user} = setup_user("admin")
      {:ok, view, _html} = live(conn |> login(user), ~p"/app/settings/availability")

      view |> element("button", "Add Availability") |> render_click()

      html =
        view
        |> element("#availability-form")
        |> render_submit(%{
          "availability_rule" => %{
            "day_of_week" => "1",
            "start_time" => "09:00:00",
            "end_time" => "17:00:00"
          }
        })

      assert html =~ "Monday"
      assert html =~ "09:00"
    end

    test "changing the timezone selector updates the user", %{conn: conn} do
      {_tenant, user} = setup_user("admin")
      {:ok, view, _html} = live(conn |> login(user), ~p"/app/settings/availability")

      render_change(view, "update_timezone", %{"timezone" => "Europe/Rome"})

      assert Repo.get!(User, user.id).timezone == "Europe/Rome"
    end
  end

  describe "company availability page" do
    test "admin can open the page and add a company rule", %{conn: conn} do
      {tenant, user} = setup_user("admin")
      {:ok, view, _html} = live(conn |> login(user), ~p"/app/settings/company-availability")

      view |> element("button", "Add Time Slot") |> render_click()

      html =
        view
        |> element("#company-availability-form")
        |> render_submit(%{
          "availability_rule" => %{
            "day_of_week" => "1",
            "start_time" => "09:00:00",
            "end_time" => "17:00:00"
          }
        })

      assert html =~ "Monday"
      assert Availability.list_company_rules(tenant.id) != []
    end

    test "non-admin is redirected away", %{conn: conn} do
      {_tenant, user} = setup_user("member")

      assert {:error, {:redirect, %{to: to}}} =
               live(conn |> login(user), ~p"/app/settings/company-availability")

      refute to =~ "company-availability"
    end

    test "changing the company timezone updates the tenant", %{conn: conn} do
      {tenant, user} = setup_user("admin")
      {:ok, view, _html} = live(conn |> login(user), ~p"/app/settings/company-availability")

      render_change(view, "update_timezone", %{"timezone" => "Asia/Tokyo"})

      assert Repo.get!(Treby.Tenants.Tenant, tenant.id).timezone == "Asia/Tokyo"
    end
  end
end
