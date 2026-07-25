defmodule TrebyWeb.Hooks.RequireRole do
  @moduledoc """
  LiveView on_mount hook that checks user role against required role.
  """

  import Phoenix.LiveView, only: [put_flash: 3, redirect: 2]
  alias Treby.Accounts

  def on_mount(%{role: required_role}, _params, session, socket) do
    user = Accounts.get_user!(session["user_id"])

    if user && user.role == required_role do
      {:cont, socket}
    else
      socket =
        socket
        |> put_flash(:error, "You don't have permission to access this page.")
        |> redirect(to: "/app")

      {:halt, socket}
    end
  end

  def on_mount(_arg, _params, _session, socket) do
    {:cont, socket}
  end
end
