defmodule TrebyWeb.Hooks.RequireRole do
  @moduledoc """
  LiveView on_mount hook that checks membership role against required role.
  """

  import Phoenix.LiveView, only: [put_flash: 3, redirect: 2]

  def on_mount(
        %{role: required_role},
        %{"tenant_slug" => slug} = _params,
        %{"user_id" => user_id} = _session,
        socket
      ) do
    tenant = Treby.Tenants.get_tenant_by_slug(slug)

    role =
      cond do
        socket.assigns[:current_membership] -> socket.assigns.current_membership.role
        tenant -> (Treby.Memberships.get_membership(user_id, tenant.id) || %{}).role
        true -> nil
      end

    if role == required_role do
      {:cont, socket}
    else
      socket =
        socket
        |> put_flash(:error, "You don't have permission to access this page.")
        |> redirect(to: "/#{slug}/app")

      {:halt, socket}
    end
  end

  def on_mount(%{role: required_role}, _params, %{"user_id" => user_id} = session, socket) do
    # Fallback for non-slug routes (should not happen for /app)
    slug =
      session["tenant_slug"] ||
        (socket.assigns[:current_tenant] && socket.assigns.current_tenant.slug)

    role =
      if socket.assigns[:current_membership] do
        socket.assigns.current_membership.role
      else
        user = Treby.Accounts.get_user!(user_id)
        Map.get(user, :role)
      end

    if role == required_role do
      {:cont, socket}
    else
      redirect_to = if slug, do: "/#{slug}/app", else: "/choose-tenant"

      socket =
        socket
        |> put_flash(:error, "You don't have permission to access this page.")
        |> redirect(to: redirect_to)

      {:halt, socket}
    end
  end

  def on_mount(_arg, _params, _session, socket) do
    {:cont, socket}
  end
end
