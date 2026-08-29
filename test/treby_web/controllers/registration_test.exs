defmodule TrebyWeb.RegistrationTest do
  use TrebyWeb.ConnCase, async: true

  alias Treby.Accounts
  alias Treby.Accounts.User

  defp unique_email do
    "test-#{System.unique_integer([:positive])}@example.com"
  end

  defp extract_code(email) do
    body =
      case email.text_body do
        %{data: data} -> data
        body when is_binary(body) -> body
      end

    [code] = Regex.run(~r/\b(\d{6})\b/, body, capture: :all_but_first)
    code
  end

  defp send_code(conn, email) do
    conn = post(conn, ~p"/register", %{"user" => %{"email" => email}})
    assert redirected_to(conn) == "/register/verify"

    assert_receive {:email, sent}
    assert sent.subject == "Verify your email address"
    {conn, extract_code(sent)}
  end

  defp verify_email(conn, code) do
    post(conn, ~p"/register/verify", %{"code" => code})
  end

  defp submit_full_form(conn, attrs) do
    base = %{
      "company_name" => "Test Corp",
      "name" => "Test User",
      "password" => "password123",
      "password_confirmation" => "password123",
      "tos_accepted" => "true"
    }

    post(conn, ~p"/register", %{"user" => Map.merge(base, attrs)})
  end

  describe "email step" do
    test "shows the email step on GET /register", %{conn: conn} do
      conn = get(conn, ~p"/register")
      html = html_response(conn, 200)
      assert html =~ "Send verification code"
      assert html =~ "user_email"
    end

    test "sends a verification code and redirects to the verify page", %{conn: conn} do
      email = unique_email()
      {conn, code} = send_code(conn, email)
      assert String.length(code) == 6
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "verification code to #{email}"
    end

    test "invalid email format shows an inline error", %{conn: conn} do
      conn = post(conn, ~p"/register", %{"user" => %{"email" => "not-an-email"}})
      assert html_response(conn, 422) =~ "must have the @ sign and no spaces"
    end

    test "already registered email shows a field error and sends no code", %{conn: conn} do
      email = unique_email()

      {:ok, tenant} = Treby.Tenants.create_tenant(%{name: "First Corp #{unique_email()}"})

      tenant
      |> Ecto.build_assoc(:users)
      |> User.changeset(%{
        email: email,
        password: "password123",
        name: "Existing User",
        role: "admin"
      })
      |> Treby.Repo.insert!()

      conn = post(conn, ~p"/register", %{"user" => %{"email" => email}})
      assert html_response(conn, 422) =~ "has already been taken"
    end

    test "rate limits repeated code requests for the same email", %{conn: conn} do
      email = unique_email()
      {conn, _} = send_code(conn, email)

      conn = post(conn, ~p"/register", %{"user" => %{"email" => email}})
      assert redirected_to(conn) == "/register/verify"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "wait a moment"
    end
  end

  describe "code verification" do
    test "redirects to the email step when no code was requested", %{conn: conn} do
      conn = get(conn, ~p"/register/verify")
      assert redirected_to(conn) == "/register"
    end

    test "verifies a correct code and unlocks the full form", %{conn: conn} do
      email = unique_email()
      {conn, code} = send_code(conn, email)

      conn = verify_email(conn, code)
      assert redirected_to(conn) == "/register"

      conn = get(conn, ~p"/register")
      html = html_response(conn, 200)
      assert html =~ "Create account"
      assert html =~ "readonly"
      assert html =~ email
    end

    test "rejects an incorrect code", %{conn: conn} do
      email = unique_email()
      {conn, _} = send_code(conn, email)

      conn = verify_email(conn, "000000")
      assert redirected_to(conn) == "/register/verify"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "Invalid or expired"
    end

    test "locks the code after too many attempts", %{conn: conn} do
      email = unique_email()
      {conn, _} = send_code(conn, email)

      conn =
        Enum.reduce(1..6, conn, fn _, conn ->
          verify_email(conn, "000000")
        end)

      assert redirected_to(conn) == "/register/verify"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "Invalid or expired"
    end
  end

  describe "full registration" do
    test "creates an account with the verified email and logs in", %{conn: conn} do
      email = unique_email()
      {conn, code} = send_code(conn, email)
      conn = verify_email(conn, code)

      conn = submit_full_form(conn, %{})
      assert redirected_to(conn) == "/app"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Welcome to Treby!"
      assert get_session(conn, "user_id")
      assert is_nil(get_session(conn, "verified_email"))
    end

    test "uses the verified email from the session, ignoring client-supplied email", %{conn: conn} do
      email = unique_email()
      other = unique_email()
      {conn, code} = send_code(conn, email)
      conn = verify_email(conn, code)

      conn = submit_full_form(conn, %{"email" => other})
      assert redirected_to(conn) == "/app"

      user = Accounts.get_user!(get_session(conn, "user_id"))
      assert user.email == email
    end

    test "mismatched passwords show an inline error", %{conn: conn} do
      email = unique_email()
      {conn, code} = send_code(conn, email)
      conn = verify_email(conn, code)

      conn = submit_full_form(conn, %{"password_confirmation" => "different_password"})
      assert html_response(conn, 422) =~ "does not match password"
    end

    test "missing ToS acceptance shows an inline error", %{conn: conn} do
      email = unique_email()
      {conn, code} = send_code(conn, email)
      conn = verify_email(conn, code)

      conn = submit_full_form(conn, %{"tos_accepted" => "false"})
      assert html_response(conn, 422) =~ "must be accepted"
    end

    test "derives a unique slug from the company name", %{conn: conn} do
      email = unique_email()
      {conn, code} = send_code(conn, email)
      conn = verify_email(conn, code)

      unique = System.unique_integer([:positive])
      conn = submit_full_form(conn, %{"company_name" => "Tech Corp #{unique}"})
      assert redirected_to(conn) == "/app"

      tenant = Treby.Tenants.get_tenant_by_slug!("tech-corp-#{unique}")
      assert tenant.name == "Tech Corp #{unique}"
    end

    test "a full form without a verified email is treated as the email step", %{conn: conn} do
      conn = submit_full_form(conn, %{"email" => unique_email()})
      assert redirected_to(conn) == "/register/verify"
    end
  end
end
