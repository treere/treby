defmodule TrebyWeb.AuthFlowTest do
  use TrebyWeb.ConnCase, async: false

  alias Treby.{Tenants, Repo}
  alias Treby.Accounts.User

  defp setup_tenant do
    {:ok, tenant} =
      Tenants.create_tenant(%{
        name: "Auth Test Corp",
        slug: "auth-test-#{System.unique_integer([:positive])}"
      })

    {:ok, user} =
      tenant
      |> Ecto.build_assoc(:users)
      |> User.changeset(%{
        email: "auth-test-#{System.unique_integer([:positive])}@test.com",
        password: "password123",
        name: "Auth User",
        role: "admin"
      })
      |> Repo.insert()

    {tenant, user}
  end

  describe "authentication flow" do
    test "user can log in with valid credentials", %{conn: conn} do
      {_tenant, user} = setup_tenant()

      conn =
        post(conn, ~p"/session", %{
          "user" => %{"email" => user.email, "password" => "password123"}
        })

      assert redirected_to(conn) == "/app"
    end

    test "user cannot log in with invalid password", %{conn: conn} do
      {_tenant, user} = setup_tenant()

      conn =
        post(conn, ~p"/session", %{
          "user" => %{"email" => user.email, "password" => "wrongpassword"}
        })

      assert redirected_to(conn) == "/login"
    end

    test "user cannot log in with nonexistent email", %{conn: conn} do
      conn =
        post(conn, ~p"/session", %{
          "user" => %{"email" => "nonexistent@test.com", "password" => "password123"}
        })

      assert redirected_to(conn) == "/login"
    end

    test "user can log out", %{conn: conn} do
      {_tenant, user} = setup_tenant()

      conn =
        conn
        |> init_test_session(%{
          "user_id" => user.id,
          "tenant_id" => user.tenant_id
        })
        |> delete(~p"/session")

      assert redirected_to(conn) == "/"
    end

    test "registered user can log in", %{conn: conn} do
      email = "reg-#{System.unique_integer([:positive])}@test.com"

      conn =
        post(conn, ~p"/register", %{
          "user" => %{
            "email" => email,
            "password" => "password123",
            "password_confirmation" => "password123",
            "tos_accepted" => "true",
            "name" => "Reg User",
            "company_name" => "Reg Corp",
            "company_slug" => "reg-corp-#{System.unique_integer([:positive])}"
          }
        })

      assert redirected_to(conn) == "/app"
    end
  end
end
