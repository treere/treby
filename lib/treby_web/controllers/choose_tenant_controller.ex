defmodule TrebyWeb.ChooseTenantController do
  use TrebyWeb, :controller

  def choose(conn, %{"slug" => slug}) do
    user = conn.assigns.current_user

    case Treby.Memberships.get_membership(user.id, Treby.Tenants.get_tenant_by_slug(slug).id) do
      nil ->
        conn
        |> put_flash(:error, "You don't belong to that workspace")
        |> redirect(to: ~p"/choose-tenant")

      _membership ->
        redirect(conn, to: ~p"/#{slug}/app")
    end
  end

  def choose(conn, _params) do
    conn
    |> put_flash(:error, "Invalid workspace")
    |> redirect(to: ~p"/choose-tenant")
  end
end
