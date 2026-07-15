defmodule TrebyWeb.InviteController do
  use TrebyWeb, :controller

  alias Treby.{Tenants, Repo, Invites}
  alias Treby.Accounts.User

  def show(conn, %{"token" => token}) do
    case Invites.get_invite_by_token(token) do
      nil ->
        conn
        |> put_flash(:error, "Invalid or expired invite link")
        |> redirect(to: ~p"/login")

      invite ->
        tenant = Tenants.get_tenant!(invite.tenant_id)

        conn
        |> assign(:invite, invite)
        |> assign(:tenant, tenant)
        |> render("show.html")
    end
  end

  def create(conn, %{"token" => token, "user" => user_params}) do
    case Invites.get_invite_by_token(token) do
      nil ->
        conn
        |> put_flash(:error, "Invalid or expired invite link")
        |> redirect(to: ~p"/login")

      invite ->
        tenant = Tenants.get_tenant!(invite.tenant_id)

        result =
          tenant
          |> Ecto.build_assoc(:users)
          |> User.changeset(%{
            "name" => user_params["name"],
            "email" => invite.email,
            "password" => user_params["password"],
            "role" => invite.role
          })
          |> Repo.insert()

        case result do
          {:ok, user} ->
            Invites.accept_invite(invite)

            conn
            |> put_session("user_id", user.id)
            |> put_session("tenant_id", tenant.id)
            |> put_flash(:info, "Welcome to #{tenant.name}!")
            |> redirect(to: ~p"/app")

          {:error, _changeset} ->
            tenant = Tenants.get_tenant!(invite.tenant_id)

            conn
            |> assign(:invite, invite)
            |> assign(:tenant, tenant)
            |> put_flash(:error, "Could not create account. Email may already be registered.")
            |> render("show.html")
        end
    end
  end
end
