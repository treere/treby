defmodule TrebyWeb.RegistrationTest do
  use TrebyWeb.ConnCase, async: true

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
    test "mismatched passwords shows error", %{conn: conn} do
      unique = System.unique_integer([:positive])

      conn =
        post(conn, ~p"/register", %{
          "user" => %{
            "company_name" => "Test Corp",
            "company_slug" => "test-#{unique}",
            "name" => "Test User",
            "email" => "test-#{unique}@example.com",
            "password" => "password123",
            "password_confirmation" => "different_password",
            "tos_accepted" => "true"
          }
        })

      assert redirected_to(conn) == "/register"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "Passwords do not match"
    end

    test "missing ToS acceptance shows error", %{conn: conn} do
      unique = System.unique_integer([:positive])

      conn =
        post(conn, ~p"/register", %{
          "user" => %{
            "company_name" => "Test Corp",
            "company_slug" => "test-#{unique}",
            "name" => "Test User",
            "email" => "test-#{unique}@example.com",
            "password" => "password123",
            "password_confirmation" => "password123",
            "tos_accepted" => "false"
          }
        })

      assert redirected_to(conn) == "/register"

      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~
               "You must accept the Terms of Service"
    end

    test "successful registration with all fields", %{conn: conn} do
      unique = System.unique_integer([:positive])

      conn =
        post(conn, ~p"/register", %{
          "user" => %{
            "company_name" => "Test Corp",
            "company_slug" => "test-#{unique}",
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
