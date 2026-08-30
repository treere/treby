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

    {:ok, _} =
      Treby.Memberships.create_membership(%{
        user_id: user.id,
        tenant_id: tenant.id,
        role: user.role
      })

    {tenant, user}
  end

  describe "authentication flow" do
    test "user can log in with valid credentials", %{conn: conn} do
      {tenant, user} = setup_tenant()

      conn =
        post(conn, ~p"/session", %{
          "user" => %{"email" => user.email, "password" => "password123"}
        })

      assert redirected_to(conn) == "/#{tenant.slug}/app"
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

      conn = post(conn, ~p"/register", %{"user" => %{"email" => email}})
      assert redirected_to(conn) == "/register/verify"

      assert_receive {:email, sent}

      body =
        case sent.text_body do
          %{data: data} -> data
          body when is_binary(body) -> body
        end

      [code] = Regex.run(~r/\b(\d{6})\b/, body, capture: :all_but_first)

      conn = post(conn, ~p"/register/verify", %{"code" => code})
      assert redirected_to(conn) == "/register"

      conn =
        post(conn, ~p"/register", %{
          "user" => %{
            "password" => "password123",
            "password_confirmation" => "password123",
            "tos_accepted" => "true",
            "name" => "Reg User",
            "company_name" => "Reg Corp"
          }
        })

      assert redirected_to(conn) =~ ~r"/reg-corp.*\/app"
    end
  end

  describe "localization" do
    test "register page renders in Italian when locale is Italian", %{conn: conn} do
      conn =
        conn
        |> init_test_session(%{"locale" => "it"})
        |> get(~p"/register")

      html = html_response(conn, 200)
      assert html =~ "Crea il tuo account"
      assert html =~ "Invia codice di verifica"
      assert html =~ "Indirizzo email"
    end

    test "register page renders in English by default", %{conn: conn} do
      conn = get(conn, ~p"/register")
      html = html_response(conn, 200)
      assert html =~ "Create your account"
      assert html =~ "Send verification code"
      assert html =~ "Email address"
    end

    test "login page renders in Italian when locale is Italian", %{conn: conn} do
      conn =
        conn
        |> init_test_session(%{"locale" => "it"})
        |> get(~p"/login")

      html = html_response(conn, 200)
      assert html =~ "Accedi al tuo account"
      assert html =~ "Password dimenticata?"
    end

    test "password reset page renders in Italian when locale is Italian", %{conn: conn} do
      conn =
        conn
        |> init_test_session(%{"locale" => "it"})
        |> get(~p"/reset-password")

      html = html_response(conn, 200)
      assert html =~ "Reimposta la tua password"
      assert html =~ "Invia link di reimpostazione"
    end

    test "invalid login shows Italian error flash when locale is Italian", %{conn: conn} do
      conn =
        conn
        |> init_test_session(%{"locale" => "it"})
        |> post(~p"/session", %{
          "user" => %{"email" => "nonexistent@test.com", "password" => "password123"}
        })

      assert redirected_to(conn) == "/login"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "Email o password non validi"
    end

    test "logout shows Italian confirmation flash when locale is Italian", %{conn: conn} do
      {_tenant, user} = setup_tenant()

      conn =
        conn
        |> init_test_session(%{
          "locale" => "it",
          "user_id" => user.id,
          "tenant_id" => user.tenant_id
        })
        |> delete(~p"/session")

      assert redirected_to(conn) == "/"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Disconnessione riuscita"
    end

    test "verification code flash preserves email in Italian", %{conn: conn} do
      email = "it-#{System.unique_integer([:positive])}@test.com"

      conn =
        conn
        |> init_test_session(%{"locale" => "it"})
        |> post(~p"/register", %{"user" => %{"email" => email}})

      assert redirected_to(conn) == "/register/verify"

      assert_receive {:email, _sent}

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~
               "Abbiamo inviato un codice di verifica a #{email}"
    end

    test "invalid verification code shows Italian error flash", %{conn: conn} do
      conn =
        conn
        |> init_test_session(%{"locale" => "it", "registration_email" => "it-code@test.com"})
        |> post(~p"/register/verify", %{"code" => "000000"})

      assert redirected_to(conn) == "/register/verify"

      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~
               "Codice non valido o scaduto. Riprova."
    end
  end
end
