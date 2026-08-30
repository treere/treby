defmodule TrebyWeb.Plugs.RequireMembership do
  @moduledoc """
  Verifies the authenticated user has a membership for the tenant identified by
  the URL slug. Assigns current_tenant, current_membership and available_tenants.
  """

  import Plug.Conn
  alias Treby.Tenants
  alias Treby.Memberships

  def init(opts), do: opts

  def call(conn, _opts) do
    tenant_slug = conn.path_params["tenant_slug"] || conn.params["tenant_slug"]

    tenant =
      if tenant_slug do
        Tenants.get_tenant_by_slug(tenant_slug)
      else
        nil
      end

    case tenant do
      nil ->
        conn
        |> put_resp_content_type("text/html")
        |> send_resp(404, "Not found")
        |> halt()

      tenant ->
        user = conn.assigns[:current_user]

        case Memberships.get_membership(user.id, tenant.id) do
          nil ->
            conn
            |> Phoenix.Controller.put_flash(:error, "You don't belong to that workspace")
            |> Phoenix.Controller.redirect(to: "/choose-tenant")
            |> halt()

          membership ->
            available = Memberships.list_tenants_for_user(user.id)

            conn
            |> assign(:current_tenant, tenant)
            |> assign(:current_membership, membership)
            |> assign(:available_tenants, available)
        end
    end
  end
end
