defmodule TrebyWeb.TenantController do
  use TrebyWeb, :controller

  def create(conn, %{"tenant" => %{"name" => name}}) do
    user = conn.assigns.current_user

    case Treby.Tenants.create_tenant(%{name: name}) do
      {:ok, tenant} ->
        {:ok, _membership} =
          Treby.Memberships.create_membership(%{
            user_id: user.id,
            tenant_id: tenant.id,
            role: "admin"
          })

        conn
        |> put_flash(:info, gettext("Workspace created"))
        |> redirect(to: ~p"/#{tenant.slug}/app")

      {:error, _changeset} ->
        conn
        |> put_flash(:error, gettext("Could not create workspace"))
        |> redirect(to: ~p"/choose-tenant")
    end
  end

  def create(conn, _params) do
    conn
    |> put_flash(:error, gettext("Name is required"))
    |> redirect(to: ~p"/choose-tenant")
  end
end
