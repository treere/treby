defmodule TrebyWeb.Hooks.RequireMembership do
  use Gettext, backend: TrebyWeb.Gettext

  @moduledoc """
  LiveView on_mount that loads tenant from slug and verifies membership.
  Assigns current_user, current_tenant, current_membership, current_actor,
  available_tenants.
  """

  import Phoenix.LiveView, only: [put_flash: 3, redirect: 2]
  import Phoenix.Component, only: [assign: 3]

  alias Treby.Authorization.Actor

  def on_mount(
        :default,
        %{"tenant_slug" => slug} = _params,
        %{"user_id" => user_id} = _session,
        socket
      ) do
    case Treby.Memberships.access_for(user_id, slug) do
      {:ok, %{tenant: tenant, membership: membership, available: available}} ->
        # Identity lookup by PK; membership enforced right below.
        user = Treby.Repo.get!(Treby.Accounts.User, user_id, skip_tenant_id: true)
        Treby.Repo.put_tenant_id(tenant.id)

        {:cont,
         socket
         |> assign(:current_user, user)
         |> assign(:current_tenant, tenant)
         |> assign(:current_membership, membership)
         |> assign(:current_actor, Actor.from(membership, tenant))
         |> assign(:available_tenants, available)}

      {:error, _} ->
        {:halt,
         socket
         |> put_flash(:error, gettext("You don't belong to that workspace"))
         |> redirect(to: "/choose-tenant")}
    end
  end

  def on_mount(:default, _params, %{"user_id" => user_id}, socket) do
    # Legacy /app fallback: pick first membership's tenant.
    # Identity lookup by PK; membership enforced right below.
    user = Treby.Repo.get!(Treby.Accounts.User, user_id, skip_tenant_id: true)
    available = Treby.Memberships.list_tenants_for_user(user_id, skip_tenant_id: true)

    case available do
      [%{tenant: tenant, membership: membership} | _] ->
        Treby.Repo.put_tenant_id(tenant.id)

        {:cont,
         socket
         |> assign(:current_user, user)
         |> assign(:current_tenant, tenant)
         |> assign(:current_membership, membership)
         |> assign(:current_actor, Actor.from(membership, tenant))
         |> assign(:available_tenants, available)}

      [] ->
        {:halt,
         socket |> put_flash(:error, gettext("No workspace found")) |> redirect(to: "/login")}
    end
  end

  def on_mount(:default, _params, _session, socket) do
    {:halt,
     socket |> put_flash(:error, gettext("You must be logged in")) |> redirect(to: "/login")}
  end
end
