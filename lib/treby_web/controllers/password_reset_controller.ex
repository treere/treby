defmodule TrebyWeb.PasswordResetController do
  use TrebyWeb, :controller

  alias Treby.Accounts
  alias Treby.PasswordResetEmail
  alias Treby.Mailer

  def new(conn, _params) do
    render(conn, "new.html")
  end

  def create(conn, %{"email" => email}) do
    # Always show the same message to prevent user enumeration
    message = "If an account exists with that email, you'll receive a reset link shortly"

    case Accounts.get_user_by_email(email) do
      nil ->
        conn
        |> put_flash(:info, message)
        |> redirect(to: ~p"/reset-password")

      user ->
        {:ok, raw_token, _token_record} = Accounts.generate_reset_token(user)
        reset_url = ~p"/reset-password/#{raw_token}"

        user
        |> PasswordResetEmail.reset_email(reset_url)
        |> Mailer.deliver()

        conn
        |> put_flash(:info, message)
        |> redirect(to: ~p"/reset-password")
    end
  end

  def edit(conn, %{"token" => token}) do
    case Accounts.get_user_by_reset_token(token) do
      {:error, :invalid_token} ->
        conn
        |> put_flash(:error, "Invalid or expired reset link")
        |> redirect(to: ~p"/reset-password")

      {:ok, _user, token_record} ->
        conn
        |> assign(:token, token)
        |> assign(:token_record, token_record)
        |> render("edit.html")
    end
  end

  def update(conn, %{"token" => token, "password" => password}) do
    case Accounts.get_user_by_reset_token(token) do
      {:error, :invalid_token} ->
        conn
        |> put_flash(:error, "Invalid or expired reset link")
        |> redirect(to: ~p"/reset-password")

      {:ok, user, token_record} ->
        if String.length(password) < 6 do
          conn
          |> put_flash(:error, "Password must be at least 6 characters")
          |> redirect(to: ~p"/reset-password/#{token}")
        else
          case Accounts.reset_password(user, token_record, password) do
            {:ok, _updated_user} ->
              conn
              |> put_flash(:info, "Password has been reset. Please sign in.")
              |> redirect(to: ~p"/login")

            {:error, _changeset} ->
              conn
              |> put_flash(:error, "Could not reset password. Please try again.")
              |> redirect(to: ~p"/reset-password")
          end
        end
    end
  end
end
