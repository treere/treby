defmodule TrebyWeb.SessionController do
  use TrebyWeb, :controller

  alias Treby.Accounts

  def new(conn, _params) do
    render(conn, "new.html")
  end

  def create(conn, %{"user" => %{"email" => email, "password" => password}}) do
    case Accounts.authenticate_user(email, password) do
      {:ok, user} ->
        conn
        |> put_session("user_id", user.id)
        |> put_session("tenant_id", user.tenant_id)
        |> put_flash(:info, "Welcome back!")
        |> redirect(to: ~p"/app")

      {:error, :invalid_credentials} ->
        conn
        |> put_flash(:error, "Invalid email or password")
        |> redirect(to: ~p"/login")
    end
  end

  def delete(conn, _params) do
    conn
    |> configure_session(drop: true)
    |> put_flash(:info, "Logged out successfully")
    |> redirect(to: ~p"/")
  end
end
