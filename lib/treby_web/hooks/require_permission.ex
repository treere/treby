defmodule TrebyWeb.Hooks.RequirePermission do
  use Gettext, backend: TrebyWeb.Gettext

  @moduledoc """
  LiveView on_mount hook that checks an action permission against the
  membership effective set. Hides by redirect: denied navigation goes to the
  workspace dashboard with a permission flash.
  """

  import Phoenix.LiveView, only: [put_flash: 3, redirect: 2]

  def on_mount(
        %{action: action},
        %{"tenant_slug" => slug} = _params,
        %{"user_id" => _} = _session,
        socket
      ) do
    check(socket, slug, List.wrap(action), :slug)
  end

  def on_mount(
        %{actions: actions},
        %{"tenant_slug" => slug} = _params,
        %{"user_id" => _} = _session,
        socket
      ) do
    check(socket, slug, List.wrap(actions), :slug)
  end

  def on_mount(%{action: action}, _params, %{"user_id" => _} = session, socket) do
    slug =
      session["tenant_slug"] ||
        (socket.assigns[:current_tenant] && socket.assigns.current_tenant.slug)

    check(socket, slug, List.wrap(action), :session)
  end

  def on_mount(%{actions: actions}, _params, %{"user_id" => _} = session, socket) do
    slug =
      session["tenant_slug"] ||
        (socket.assigns[:current_tenant] && socket.assigns.current_tenant.slug)

    check(socket, slug, List.wrap(actions), :session)
  end

  def on_mount(_arg, _params, _session, socket) do
    {:cont, socket}
  end

  defp check(socket, slug, actions, _source) do
    tenant =
      (slug && Treby.Tenants.get_tenant_by_slug(slug)) || socket.assigns[:current_tenant]

    membership =
      socket.assigns[:current_membership] || current_membership(socket, tenant)

    effective =
      if is_nil(tenant) or is_nil(membership) do
        MapSet.new()
      else
        Treby.Authorization.effective_for(tenant.id, membership.role)
      end

    if Enum.any?(actions, &Treby.Authorization.can?(effective, &1)) do
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

  defp current_membership(socket, tenant) do
    user_id =
      socket.assigns[:current_user] && socket.assigns.current_user.id

    if user_id && tenant do
      Treby.Memberships.get_membership(user_id, tenant.id)
    end
  end
end
