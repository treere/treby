defmodule TrebyWeb.Hooks.RequireMembership do
  use Gettext, backend: TrebyWeb.Gettext

  @moduledoc """
  LiveView on_mount that loads tenant from slug and verifies membership.
  Assigns current_user, current_tenant, current_membership, available_tenants.
  """

  import Phoenix.LiveView, only: [put_flash: 3, redirect: 2]
  import Phoenix.Component, only: [assign: 3]

  def on_mount(
        :default,
        %{"tenant_slug" => slug} = _params,
        %{"user_id" => user_id} = _session,
        socket
      ) do
    with %Treby.Tenants.Tenant{} = tenant <- Treby.Tenants.get_tenant_by_slug(slug),
         %Treby.Memberships.Membership{} = membership <-
           Treby.Memberships.get_membership(user_id, tenant.id) do
      user = Treby.Repo.get!(Treby.Accounts.User, user_id)
      available = Treby.Memberships.list_tenants_for_user(user_id)

      {:cont,
       socket
       |> assign(:current_user, user)
       |> assign(:current_tenant, tenant)
       |> assign(:current_membership, membership)
       |> assign(:available_tenants, available)}
    else
      _ ->
        {:halt,
         socket
         |> put_flash(:error, gettext("You don't belong to that workspace"))
         |> redirect(to: "/choose-tenant")}
    end
  end

  def on_mount(:default, _params, %{"user_id" => user_id}, socket) do
    # Legacy /app fallback: pick first membership's tenant
    user = Treby.Repo.get!(Treby.Accounts.User, user_id)
    available = Treby.Memberships.list_tenants_for_user(user_id)

    case available do
      [%{tenant: tenant, membership: membership} | _] ->
        {:cont,
         socket
         |> assign(:current_user, user)
         |> assign(:current_tenant, tenant)
         |> assign(:current_membership, membership)
         |> assign(:available_tenants, available)}

      [] ->
        {:halt,
         socket |> put_flash(:error, gettext("No workspace found")) |> redirect(to: "/login")}

      _ ->
        {:cont,
         socket
         |> assign(:current_user, user)
         |> assign(:available_tenants, available)}
    end
  end

  def on_mount(:default, _params, _session, socket) do
    {:halt,
     socket |> put_flash(:error, gettext("You must be logged in")) |> redirect(to: "/login")}
  end
end
