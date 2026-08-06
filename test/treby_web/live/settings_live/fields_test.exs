defmodule TrebyWeb.SettingsLive.FieldsTest do
  use TrebyWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias Treby.{Tenants, Repo}
  alias Treby.Accounts.User

  defp setup_tenant do
    {:ok, tenant} =
      Tenants.create_tenant(%{
        name: "Fields Test Corp",
        slug: "fields-test-#{System.unique_integer([:positive])}"
      })

    {:ok, user} =
      tenant
      |> Ecto.build_assoc(:users)
      |> User.changeset(%{
        email: "fields-#{System.unique_integer([:positive])}@test.com",
        password: "password123",
        name: "Fields User",
        role: "admin"
      })
      |> Repo.insert()

    {tenant, user}
  end

  defp login_user(conn, user) do
    conn
    |> init_test_session(%{
      "user_id" => user.id,
      "tenant_id" => user.tenant_id
    })
  end

  describe "custom fields page" do
    test "shows empty state when no custom fields exist", %{conn: conn} do
      {_tenant, user} = setup_tenant()
      conn = login_user(conn, user)

      {:ok, _view, html} = live(conn, ~p"/app/settings/fields")

      assert html =~ "Custom Fields"
      assert html =~ "No custom fields defined yet"
    end

    test "renders the create form when clicking Add Field", %{conn: conn} do
      {_tenant, user} = setup_tenant()
      conn = login_user(conn, user)

      {:ok, view, _html} = live(conn, ~p"/app/settings/fields")

      view |> element("button", "+ Add Field") |> render_click()

      assert has_element?(view, "#field-form")
      assert has_element?(view, "#field-form [name='custom_field[name]']")
    end

    test "saves a select custom field with options", %{conn: conn} do
      {tenant, user} = setup_tenant()
      conn = login_user(conn, user)

      {:ok, view, _html} = live(conn, ~p"/app/settings/fields")
      view |> element("button", "+ Add Field") |> render_click()

      view
      |> form("#field-form", %{"custom_field" => %{"field_type" => "select"}})
      |> render_change()

      html =
        view
        |> form("#field-form", %{
          "custom_field" => %{
            "name" => "Seniority Level",
            "field_type" => "select",
            "applies_to" => "candidate",
            "required" => "true"
          },
          "options_text" => "Junior\nMid\nSenior"
        })
        |> render_submit()

      assert html =~ "Field saved"
      assert html =~ "Seniority Level"

      field = Treby.Customization.list_custom_fields(tenant.id) |> List.first()
      assert field.name == "Seniority Level"
      assert field.field_type == "select"
      assert field.options == ["Junior", "Mid", "Senior"]
    end

    test "validate keeps name and options when toggling the field type", %{conn: conn} do
      {_tenant, user} = setup_tenant()
      conn = login_user(conn, user)

      {:ok, view, _html} = live(conn, ~p"/app/settings/fields")
      view |> element("button", "+ Add Field") |> render_click()

      view
      |> form("#field-form", %{
        "custom_field" => %{"name" => "Seniority Level", "field_type" => "select"}
      })
      |> render_change()

      html =
        view
        |> form("#field-form", %{
          "custom_field" => %{"field_type" => "select"},
          "options_text" => "Junior\nMid\nSenior"
        })
        |> render_change()

      assert html =~ "Junior"

      html =
        view
        |> form("#field-form", %{
          "custom_field" => %{
            "name" => "Seniority Level",
            "field_type" => "text",
            "applies_to" => "candidate"
          }
        })
        |> render_change()

      assert html =~ "Seniority Level"

      html =
        view
        |> form("#field-form", %{
          "custom_field" => %{
            "name" => "Seniority Level",
            "field_type" => "select",
            "applies_to" => "candidate"
          }
        })
        |> render_change()

      assert html =~ "Seniority Level"

      html =
        view
        |> form("#field-form", %{
          "custom_field" => %{"field_type" => "select"},
          "options_text" => "Junior\nMid\nSenior"
        })
        |> render_change()

      assert html =~ "Seniority Level"
      assert html =~ "Junior"
    end

    test "shows flash error when saving field with empty name", %{conn: conn} do
      {_tenant, user} = setup_tenant()
      conn = login_user(conn, user)

      {:ok, view, _html} = live(conn, ~p"/app/settings/fields")
      view |> element("button", "+ Add Field") |> render_click()

      html =
        view
        |> form("#field-form", %{
          "custom_field" => %{
            "name" => "",
            "field_type" => "text",
            "applies_to" => "candidate"
          }
        })
        |> render_submit()

      assert html =~ "Please review the errors below"
    end

    test "deletes a custom field via the confirm modal", %{conn: conn} do
      {tenant, user} = setup_tenant()

      {:ok, _field} =
        Treby.Customization.create_custom_field(%{
          tenant_id: tenant.id,
          name: "Temp Field",
          field_type: "text",
          applies_to: "candidate"
        })

      conn = login_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/app/settings/fields")

      assert render(view) =~ "Temp Field"

      view |> element(~s{button[phx-click="confirm_delete"]}) |> render_click()

      html =
        view
        |> element(~s{button[phx-click="do_delete_field"]})
        |> render_click()

      assert html =~ "Field deleted"
      refute render(view) =~ "Temp Field"
      assert Treby.Customization.list_custom_fields(tenant.id) == []
    end
  end
end
