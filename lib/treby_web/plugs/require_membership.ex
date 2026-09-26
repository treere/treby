defmodule TrebyWeb.Plugs.RequireMembership do
  use Gettext, backend: TrebyWeb.Gettext

  @moduledoc """
  Verifies the authenticated user has a membership for the tenant identified by
  the URL slug. Assigns current_tenant, current_membership, current_actor and
  available_tenants.
  """

  import Plug.Conn

  alias Treby.Authorization.Actor

  def init(opts), do: opts

  def call(conn, _opts) do
    tenant_slug = conn.path_params["tenant_slug"] || conn.params["tenant_slug"]
    user = conn.assigns[:current_user]

    case Treby.Memberships.access_for(user && user.id, tenant_slug) do
      {:ok, %{tenant: tenant, membership: membership, available: available}} ->
        Treby.Repo.put_tenant_id(tenant.id)

        conn
        |> assign(:current_tenant, tenant)
        |> assign(:current_membership, membership)
        |> assign(:current_actor, Actor.from(membership, tenant))
        |> assign(:available_tenants, available)

      {:error, :no_tenant} ->
        conn
        |> put_resp_content_type("text/html")
        |> send_resp(404, "Not found")
        |> halt()

      {:error, :no_membership} ->
        conn
        |> Phoenix.Controller.put_flash(:error, gettext("You don't belong to that workspace"))
        |> Phoenix.Controller.redirect(to: "/choose-tenant")
        |> halt()
    end
  end
end
