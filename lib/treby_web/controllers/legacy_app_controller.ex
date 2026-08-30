defmodule TrebyWeb.LegacyAppController do
  use TrebyWeb, :controller

  def redirect_legacy(conn, %{"path" => path}) do
    user = conn.assigns[:current_user]
    suffix = Enum.join(path, "/")
    suffix = if suffix == "", do: "", else: "/#{suffix}"

    case Treby.Memberships.list_tenants_for_user(user.id) do
      [] ->
        conn |> redirect(to: ~p"/login")

      [%{tenant: tenant}] ->
        conn |> redirect(to: "/#{tenant.slug}/app#{suffix}")

      _ ->
        # Multiple workspaces: if path is just root, go to picker, else pick first? Redirect to picker
        # Preserve query string if any via request_path
        conn |> redirect(to: ~p"/choose-tenant")
    end
  end

  def redirect_legacy(conn, _params) do
    user = conn.assigns[:current_user]

    case Treby.Memberships.list_tenants_for_user(user.id) do
      [] -> conn |> redirect(to: ~p"/login")
      [%{tenant: tenant}] -> conn |> redirect(to: "/#{tenant.slug}/app")
      _ -> conn |> redirect(to: ~p"/choose-tenant")
    end
  end
end
