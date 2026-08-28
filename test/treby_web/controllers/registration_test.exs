defmodule TrebyWeb.RegistrationTest do
  use TrebyWeb.ConnCase, async: true

  alias Treby.Accounts.User

  describe "registration form" do
    test "shows registration form on GET /register", %{conn: conn} do
      conn = get(conn, ~p"/register")
      assert html_response(conn, 200) =~ "Create your account"
      assert html_response(conn, 200) =~ "Confirm password"
      assert html_response(conn, 200) =~ "Terms of Service"
    end

    test "registration form has password confirmation field", %{conn: conn} do
      conn = get(conn, ~p"/register")
      assert html_response(conn, 200) =~ "user_password_confirmation"
    end

    test "registration form has ToS checkbox", %{conn: conn} do
      conn = get(conn, ~p"/register")
      assert html_response(conn, 200) =~ "user_tos_accepted"
    end
  end

  describe "registration validation" do
    test "mismatched passwords shows inline error", %{conn: conn} do
      unique = System.unique_integer([:positive])

      conn =
        post(conn, ~p"/register", %{
          "user" => %{
            "company_name" => "Test Corp",
            "name" => "Test User",
            "email" => "test-#{unique}@example.com",
            "password" => "password123",
            "password_confirmation" => "different_password",
            "tos_accepted" => "true"
          }
        })

      assert html_response(conn, 422) =~ "does not match password"
    end

    test "missing ToS acceptance shows inline error", %{conn: conn} do
      unique = System.unique_integer([:positive])

      conn =
        post(conn, ~p"/register", %{
          "user" => %{
            "company_name" => "Test Corp",
            "name" => "Test User",
            "email" => "test-#{unique}@example.com",
            "password" => "password123",
            "password_confirmation" => "password123",
            "tos_accepted" => "false"
          }
        })

      assert html_response(conn, 422) =~ "must be accepted"
    end

    test "successful registration with all fields", %{conn: conn} do
      unique = System.unique_integer([:positive])

      conn =
        post(conn, ~p"/register", %{
          "user" => %{
            "company_name" => "Test Corp",
            "name" => "Test User",
            "email" => "test-#{unique}@example.com",
            "password" => "password123",
            "password_confirmation" => "password123",
            "tos_accepted" => "true"
          }
        })

      assert redirected_to(conn) == "/app"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Welcome to Treby!"
    end

    test "registration without a slug derives a unique slug from the company name", %{conn: conn} do
      unique = System.unique_integer([:positive])
      name = "Tech Corp #{unique}"

      conn =
        post(conn, ~p"/register", %{
          "user" => %{
            "company_name" => name,
            "name" => "Test User",
            "email" => "test-#{unique}@example.com",
            "password" => "password123",
            "password_confirmation" => "password123",
            "tos_accepted" => "true"
          }
        })

      assert redirected_to(conn) == "/app"

      tenant = Treby.Tenants.get_tenant_by_slug!("tech-corp-#{unique}")
      assert tenant.name == name

      conn = get(conn, ~p"/#{tenant.slug}/careers")
      assert html_response(conn, 200) =~ "Open Positions"
    end

    test "registration with an already registered email shows a field-level error", %{conn: conn} do
      unique = System.unique_integer([:positive])
      email = "dup-#{unique}@example.com"

      {:ok, existing_tenant} = Treby.Tenants.create_tenant(%{name: "First Corp #{unique}"})

      existing_tenant
      |> Ecto.build_assoc(:users)
      |> User.changeset(%{
        email: email,
        password: "password123",
        name: "Existing User",
        role: "admin"
      })
      |> Treby.Repo.insert!()

      conn =
        post(conn, ~p"/register", %{
          "user" => %{
            "company_name" => "Second Corp #{unique}",
            "name" => "Test User",
            "email" => email,
            "password" => "password123",
            "password_confirmation" => "password123",
            "tos_accepted" => "true"
          }
        })

      assert html_response(conn, 422) =~ "has already been taken"
      assert html_response(conn, 422) =~ "user_email"
    end
  end

  describe "static pages" do
    test "terms page loads", %{conn: conn} do
      conn = get(conn, ~p"/terms")
      assert html_response(conn, 200) =~ "Terms of Service"
      assert html_response(conn, 200) =~ "Coming Soon"
    end

    test "privacy page loads", %{conn: conn} do
      conn = get(conn, ~p"/privacy")
      assert html_response(conn, 200) =~ "Privacy Policy"
      assert html_response(conn, 200) =~ "Coming Soon"
    end
  end
end
