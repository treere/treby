defmodule TrebyWeb.Plugs.Tenant do
  use Gettext, backend: TrebyWeb.Gettext

  @moduledoc """
  Plug for extracting and scoping the current tenant.

  For authenticated routes, extracts tenant from session.
  For public routes, extracts tenant from URL slug.
  """

  import Plug.Conn
  alias Treby.Tenants

  def init(opts), do: opts

  def call(conn, :from_session) do
    case get_session(conn, "tenant_id") do
      nil ->
        conn
        |> Phoenix.Controller.put_flash(:error, gettext("You must be logged in"))
        |> Phoenix.Controller.redirect(to: "/login")
        |> halt()

      tenant_id ->
        case Tenants.get_tenant!(tenant_id) do
          nil ->
            conn
            |> Phoenix.Controller.put_flash(:error, gettext("Tenant not found"))
            |> Phoenix.Controller.redirect(to: "/login")
            |> halt()

          tenant ->
            assign(conn, :current_tenant, tenant)
        end
    end
  end

  def call(conn, :from_slug) do
    %{"tenant_slug" => slug} = conn.path_params

    case Tenants.get_tenant_by_slug(slug) do
      nil ->
        conn
        |> put_resp_content_type("text/html")
        |> send_resp(404, "Not found")
        |> halt()

      tenant ->
        assign(conn, :current_tenant, tenant)
    end
  end
end
