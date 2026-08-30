defmodule TrebyWeb.PasswordResetTest do
  use TrebyWeb.ConnCase, async: false

  alias Treby.{Tenants, Repo, Accounts}
  alias Treby.Accounts.User
  alias Phoenix.Flash

  defp setup_tenant do
    {:ok, tenant} =
      Tenants.create_tenant(%{
        name: "Reset Test Corp",
        slug: "reset-test-#{System.unique_integer([:positive])}"
      })

    {:ok, user} =
      tenant
      |> Ecto.build_assoc(:users)
      |> User.changeset(%{
        email: "reset-test-#{System.unique_integer([:positive])}@test.com",
        password: "password123",
        name: "Reset User",
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

  describe "password reset request" do
    test "shows reset form on GET /reset-password", %{conn: conn} do
      conn = get(conn, ~p"/reset-password")
      assert html_response(conn, 200) =~ "Reset your password"
    end

    test "generates token and sends email for valid user", %{conn: conn} do
      {_tenant, user} = setup_tenant()

      conn =
        post(conn, ~p"/reset-password", %{
          "email" => user.email
        })

      assert redirected_to(conn) == "/reset-password"
      assert Flash.get(conn.assigns.flash, :info) =~ "reset link"
    end

    test "shows same message for non-existent email (user enumeration prevention)", %{conn: conn} do
      conn =
        post(conn, ~p"/reset-password", %{
          "email" => "nonexistent@test.com"
        })

      assert redirected_to(conn) == "/reset-password"
      assert Flash.get(conn.assigns.flash, :info) =~ "reset link"
    end

    test "token is stored as hash, not raw token" do
      {_tenant, user} = setup_tenant()

      {:ok, raw_token, token_record} = Accounts.generate_reset_token(user)

      # Raw token should not be in the database
      token_hash = :crypto.hash(:sha256, raw_token) |> Base.encode16(case: :lower)
      assert token_record.token_hash == token_hash

      # Verify the raw token is not stored directly
      refute Repo.get_by(
               Accounts.PasswordResetToken,
               token_hash: raw_token
             )
    end
  end

  describe "password reset token validation" do
    test "valid token shows reset form", %{conn: conn} do
      {_tenant, user} = setup_tenant()
      {:ok, raw_token, _} = Accounts.generate_reset_token(user)

      conn = get(conn, ~p"/reset-password/#{raw_token}")
      assert html_response(conn, 200) =~ "Set new password"
    end

    test "invalid token redirects with error", %{conn: conn} do
      conn = get(conn, ~p"/reset-password/invalid-token-123")
      assert redirected_to(conn) == "/reset-password"
      assert Flash.get(conn.assigns.flash, :error) =~ "Invalid or expired"
    end

    test "expired token redirects with error", %{conn: conn} do
      {_tenant, user} = setup_tenant()
      {:ok, raw_token, token_record} = Accounts.generate_reset_token(user)

      # Manually expire the token
      token_record
      |> Ecto.Changeset.change(%{
        expires_at:
          DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.add(-3600, :second)
      })
      |> Repo.update!()

      conn = get(conn, ~p"/reset-password/#{raw_token}")
      assert redirected_to(conn) == "/reset-password"
      assert Flash.get(conn.assigns.flash, :error) =~ "Invalid or expired"
    end

    test "used token redirects with error", %{conn: conn} do
      {_tenant, user} = setup_tenant()
      {:ok, raw_token, token_record} = Accounts.generate_reset_token(user)

      # Mark token as used
      token_record
      |> Ecto.Changeset.change(%{used_at: DateTime.utc_now() |> DateTime.truncate(:second)})
      |> Repo.update!()

      conn = get(conn, ~p"/reset-password/#{raw_token}")
      assert redirected_to(conn) == "/reset-password"
      assert Flash.get(conn.assigns.flash, :error) =~ "Invalid or expired"
    end
  end

  describe "password reset completion" do
    test "successful reset updates password and redirects to login", %{conn: conn} do
      {_tenant, user} = setup_tenant()
      {:ok, raw_token, _} = Accounts.generate_reset_token(user)

      conn =
        post(conn, ~p"/reset-password/#{raw_token}", %{
          "password" => "newpassword456"
        })

      assert redirected_to(conn) == "/login"
      assert Flash.get(conn.assigns.flash, :info) =~ "Password has been reset"

      # Verify the password was actually changed
      updated_user = Repo.get!(User, user.id)
      assert Bcrypt.verify_pass("newpassword456", updated_user.password_hash)
      refute Bcrypt.verify_pass("password123", updated_user.password_hash)
    end

    test "token is marked as used after successful reset", %{conn: conn} do
      {_tenant, user} = setup_tenant()
      {:ok, raw_token, token_record} = Accounts.generate_reset_token(user)

      post(conn, ~p"/reset-password/#{raw_token}", %{
        "password" => "newpassword456"
      })

      # Reload token and verify it's marked as used
      used_token = Repo.get!(Accounts.PasswordResetToken, token_record.id)
      assert used_token.used_at != nil
    end

    test "short password shows error and token remains valid", %{conn: conn} do
      {_tenant, user} = setup_tenant()
      {:ok, raw_token, token_record} = Accounts.generate_reset_token(user)

      conn =
        post(conn, ~p"/reset-password/#{raw_token}", %{
          "password" => "12345"
        })

      assert redirected_to(conn) == "/reset-password/#{raw_token}"
      assert Flash.get(conn.assigns.flash, :error) =~ "at least 6 characters"

      # Token should still be valid (not used)
      refute_token = Repo.get!(Accounts.PasswordResetToken, token_record.id)
      assert refute_token.used_at == nil
    end

    test "invalid token on update redirects with error", %{conn: conn} do
      conn =
        post(conn, ~p"/reset-password/invalid-token-123", %{
          "password" => "newpassword456"
        })

      assert redirected_to(conn) == "/reset-password"
      assert Flash.get(conn.assigns.flash, :error) =~ "Invalid or expired"
    end
  end

  describe "login page forgot password link" do
    test "login page contains forgot password link", %{conn: conn} do
      conn = get(conn, ~p"/login")
      assert html_response(conn, 200) =~ "Forgot your password?"
      assert html_response(conn, 200) =~ "/reset-password"
    end
  end

  describe "end-to-end password reset flow" do
    test "full flow: request -> email -> reset -> login with new password", %{conn: conn} do
      {_tenant, user} = setup_tenant()

      # Step 1: Request reset
      conn =
        post(conn, ~p"/reset-password", %{
          "email" => user.email
        })

      assert redirected_to(conn) == "/reset-password"

      # Step 2: Get the token (simulating email link)
      {:ok, raw_token, _} = Accounts.generate_reset_token(user)

      # Step 3: Access reset form
      conn = get(conn, ~p"/reset-password/#{raw_token}")
      assert html_response(conn, 200) =~ "Set new password"

      # Step 4: Submit new password
      conn =
        post(conn, ~p"/reset-password/#{raw_token}", %{
          "password" => "newpassword456"
        })

      assert redirected_to(conn) == "/login"
      assert Flash.get(conn.assigns.flash, :info) =~ "Password has been reset"

      # Step 5: Verify can login with new password
      conn =
        post(conn, ~p"/session", %{
          "user" => %{"email" => user.email, "password" => "newpassword456"}
        })

      assert redirected_to(conn) =~ ~r"/.+/app"
    end
  end
end
