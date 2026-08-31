defmodule TrebyWeb.SessionController do
  use TrebyWeb, :controller

  alias Treby.Accounts
  alias Treby.Memberships

  def new(conn, _params) do
    render(conn, "new.html")
  end

  def create(conn, %{"user" => %{"email" => email, "password" => password}}) do
    case Accounts.authenticate_user(email, password) do
      {:ok, user} ->
        tenants = Memberships.list_tenants_for_user(user.id)

        # audit login per first tenant if available
        case List.first(tenants) do
          %{tenant: t} ->
            Treby.Audit.log_event("auth.login", "user", user.id, %{
              tenant_id: t.id,
              actor_id: user.id,
              metadata: %{after: %{email: user.email}}
            })

          _ ->
            :ok
        end

        conn = conn |> put_session("user_id", user.id) |> delete_session("tenant_id")

        case tenants do
          [] ->
            conn
            |> put_flash(:info, gettext("Welcome back!"))
            |> redirect(to: ~p"/choose-tenant")

          [%{tenant: tenant}] ->
            conn
            |> put_flash(:info, gettext("Welcome back!"))
            |> redirect(to: ~p"/#{tenant.slug}/app")

          _ ->
            conn
            |> put_flash(:info, gettext("Welcome back!"))
            |> redirect(to: ~p"/choose-tenant")
        end

      {:error, :invalid_credentials} ->
        conn
        |> put_flash(:error, gettext("Invalid email or password"))
        |> redirect(to: ~p"/login")
    end
  end

  def delete(conn, _params) do
    conn
    |> configure_session(drop: true)
    |> put_flash(:info, gettext("Logged out successfully"))
    |> redirect(to: ~p"/")
  end
end
