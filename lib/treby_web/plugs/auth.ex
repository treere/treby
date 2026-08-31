defmodule TrebyWeb.Plugs.Auth do
  use Gettext, backend: TrebyWeb.Gettext

  @moduledoc """
  Plug for checking authentication and setting current_user.
  """

  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    case get_session(conn, "user_id") do
      nil ->
        conn
        |> Phoenix.Controller.put_flash(:error, gettext("You must be logged in"))
        |> Phoenix.Controller.redirect(to: "/login")
        |> halt()

      user_id ->
        case Treby.Repo.get(Treby.Accounts.User, user_id) do
          nil ->
            conn
            |> delete_session("user_id")
            |> Phoenix.Controller.put_flash(:error, gettext("User not found"))
            |> Phoenix.Controller.redirect(to: "/login")
            |> halt()

          user ->
            conn
            |> assign(:current_user, user)
        end
    end
  end
end
