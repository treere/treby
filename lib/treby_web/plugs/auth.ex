defmodule TrebyWeb.Plugs.Auth do
  @moduledoc """
  Plug for checking authentication and setting current_user.
  """

  import Plug.Conn
  alias Treby.Accounts

  def init(opts), do: opts

  def call(conn, _opts) do
    case get_session(conn, "user_id") do
      nil ->
        conn
        |> Phoenix.Controller.put_flash(:error, "You must be logged in")
        |> Phoenix.Controller.redirect(to: "/login")
        |> halt()

      user_id ->
        case Accounts.get_user!(user_id) do
          nil ->
            conn
            |> delete_session("user_id")
            |> Phoenix.Controller.put_flash(:error, "User not found")
            |> Phoenix.Controller.redirect(to: "/login")
            |> halt()

          user ->
            conn
            |> assign(:current_user, user)
            |> assign(:current_tenant, user.tenant)
        end
    end
  end
end
