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
            |> ensure_ai_session_token()
            |> assign(:current_user, user)
        end
    end
  end

  defp ensure_ai_session_token(conn) do
    case get_session(conn, "ai_session_token") do
      nil -> put_session(conn, "ai_session_token", new_token())
      _existing -> conn
    end
  end

  defp new_token do
    :crypto.strong_rand_bytes(16) |> Base.url_encode64(padding: false)
  end
end
