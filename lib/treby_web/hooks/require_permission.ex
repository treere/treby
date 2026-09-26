defmodule TrebyWeb.Hooks.RequirePermission do
  use Gettext, backend: TrebyWeb.Gettext

  @moduledoc """
  LiveView on_mount hook that checks an action permission against the
  membership effective set. Hides by redirect: denied navigation goes to the
  workspace dashboard with a permission flash.
  """

  import Phoenix.LiveView, only: [put_flash: 3, redirect: 2]

  def on_mount(%{action: action}, params, session, socket) do
    check(socket, slug_from(params, session, socket), List.wrap(action), session["user_id"])
  end

  def on_mount(%{actions: actions}, params, session, socket) do
    check(socket, slug_from(params, session, socket), List.wrap(actions), session["user_id"])
  end

  def on_mount(_arg, _params, _session, socket) do
    {:cont, socket}
  end

  defp slug_from(params, session, socket) do
    params["tenant_slug"] || session["tenant_slug"] ||
      (socket.assigns[:current_tenant] && socket.assigns.current_tenant.slug)
  end

  defp check(socket, _slug, _actions, nil) do
    # No user session: RequireMembership owns the login redirect; stay neutral.
    {:cont, socket}
  end

  defp check(socket, slug, actions, user_id) do
    {tenant, membership} =
      if socket.assigns[:current_tenant] && socket.assigns[:current_membership] do
        {socket.assigns.current_tenant, socket.assigns.current_membership}
      else
        case Treby.Memberships.access_for(user_id, slug) do
          {:ok, %{tenant: tenant, membership: membership}} -> {tenant, membership}
          {:error, _} -> {socket.assigns[:current_tenant], nil}
        end
      end

    actor =
      Treby.Authorization.Actor.from(%{
        current_membership: membership,
        current_tenant: tenant,
        current_user: socket.assigns[:current_user]
      })

    if Enum.any?(actions, &Treby.Authorization.Policy.can?(actor, &1)) do
      {:cont, socket}
    else
      redirect_to = if slug, do: "/#{slug}/app", else: "/choose-tenant"

      socket =
        socket
        |> put_flash(:error, gettext("You don't have permission to access this page."))
        |> redirect(to: redirect_to)

      {:halt, socket}
    end
  end
end
