defmodule TrebyWeb.InviteController do
  use TrebyWeb, :controller

  alias Treby.{Tenants, Repo, Invites, Memberships}
  alias Treby.Accounts
  alias Treby.Accounts.User

  def show(conn, %{"token" => token}) do
    case Invites.get_invite_by_token(token) do
      nil ->
        conn
        |> put_flash(:error, gettext("Invalid or expired invite link"))
        |> redirect(to: ~p"/login")

      invite ->
        tenant = Tenants.get_tenant!(invite.tenant_id)
        existing_user = Accounts.get_user_by_email(invite.email)
        current_user_id = get_session(conn, "user_id")
        current_user = if current_user_id, do: Repo.get(User, current_user_id), else: nil

        cond do
          is_nil(existing_user) ->
            conn
            |> assign(:invite, invite)
            |> assign(:tenant, tenant)
            |> assign(:existing_user, nil)
            |> assign(:needs_login, false)
            |> assign(:needs_accept, false)
            |> assign(:mismatch, false)
            |> render("show.html")

          is_nil(current_user) ->
            conn
            |> assign(:invite, invite)
            |> assign(:tenant, tenant)
            |> assign(:existing_user, existing_user)
            |> assign(:needs_login, true)
            |> assign(:needs_accept, false)
            |> assign(:mismatch, false)
            |> render("show.html")

          existing_user.id == current_user.id ->
            if Memberships.member?(existing_user.id, tenant.id) do
              conn
              |> put_flash(
                :info,
                gettext("You are already a member of %{name}", name: tenant.name)
              )
              |> redirect(to: "/#{tenant.slug}/app")
            else
              conn
              |> assign(:invite, invite)
              |> assign(:tenant, tenant)
              |> assign(:existing_user, existing_user)
              |> assign(:needs_login, false)
              |> assign(:needs_accept, true)
              |> assign(:mismatch, false)
              |> render("show.html")
            end

          true ->
            conn
            |> assign(:invite, invite)
            |> assign(:tenant, tenant)
            |> assign(:existing_user, existing_user)
            |> assign(:current_user, current_user)
            |> assign(:needs_login, false)
            |> assign(:needs_accept, false)
            |> assign(:mismatch, true)
            |> render("show.html")
        end
    end
  end

  def create(conn, %{"token" => token, "user" => user_params}) do
    case Invites.get_invite_by_token(token) do
      nil ->
        conn
        |> put_flash(:error, gettext("Invalid or expired invite link"))
        |> redirect(to: ~p"/login")

      invite ->
        tenant = Tenants.get_tenant!(invite.tenant_id)
        existing_user = Accounts.get_user_by_email(invite.email)
        current_user_id = get_session(conn, "user_id")
        current_user = if current_user_id, do: Repo.get(User, current_user_id), else: nil

        cond do
          is_nil(existing_user) ->
            # New identity: create user + membership
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
                # Create membership (may already exist via Repo hook, but ensure)
                case Memberships.create_membership(%{
                       user_id: user.id,
                       tenant_id: tenant.id,
                       role: invite.role
                     }) do
                  {:ok, _} -> :ok
                  {:error, _} -> :ok
                end

                Invites.accept_invite(invite)

                conn
                |> put_session("user_id", user.id)
                |> delete_session("tenant_id")
                |> put_flash(:info, gettext("Welcome to %{name}!", name: tenant.name))
                |> redirect(to: "/#{tenant.slug}/app")

              {:error, _changeset} ->
                conn
                |> assign(:invite, invite)
                |> assign(:tenant, tenant)
                |> assign(:existing_user, nil)
                |> assign(:needs_login, false)
                |> assign(:needs_accept, false)
                |> assign(:mismatch, false)
                |> put_flash(
                  :error,
                  gettext("Could not create account. Email may already be registered.")
                )
                |> render("show.html")
            end

          is_nil(current_user) ->
            # Existing identity but not logged in: require login
            conn
            |> put_flash(
              :error,
              gettext("Please log in as %{email} to accept this invite", email: invite.email)
            )
            |> redirect(to: ~p"/login")

          existing_user.id == current_user.id ->
            # Same user: idempotent membership creation
            case Memberships.get_membership(existing_user.id, tenant.id) do
              nil ->
                case Memberships.create_membership(%{
                       user_id: existing_user.id,
                       tenant_id: tenant.id,
                       role: invite.role
                     }) do
                  {:ok, _} -> :ok
                  {:error, _} -> :ok
                end

                Invites.accept_invite(invite)

              _ ->
                :ok
            end

            conn
            |> put_flash(:info, gettext("Welcome to %{name}!", name: tenant.name))
            |> redirect(to: "/#{tenant.slug}/app")

          true ->
            # Different user logged in
            conn
            |> assign(:invite, invite)
            |> assign(:tenant, tenant)
            |> assign(:existing_user, existing_user)
            |> assign(:current_user, current_user)
            |> assign(:needs_login, false)
            |> assign(:needs_accept, false)
            |> assign(:mismatch, true)
            |> put_flash(:error, gettext("You are logged in as a different user"))
            |> render("show.html")
        end
    end
  end

  # Handle accept without user params (for existing user same)
  def create(conn, %{"token" => token}) do
    case Invites.get_invite_by_token(token) do
      nil ->
        conn
        |> put_flash(:error, gettext("Invalid or expired invite link"))
        |> redirect(to: ~p"/login")

      invite ->
        tenant = Tenants.get_tenant!(invite.tenant_id)
        existing_user = Accounts.get_user_by_email(invite.email)
        current_user_id = get_session(conn, "user_id")
        current_user = if current_user_id, do: Repo.get(User, current_user_id), else: nil

        cond do
          is_nil(existing_user) ->
            conn
            |> assign(:invite, invite)
            |> assign(:tenant, tenant)
            |> assign(:existing_user, nil)
            |> assign(:needs_login, false)
            |> assign(:needs_accept, false)
            |> assign(:mismatch, false)
            |> render("show.html")

          is_nil(current_user) ->
            conn
            |> put_flash(
              :error,
              gettext("Please log in as %{email} to accept this invite", email: invite.email)
            )
            |> redirect(to: ~p"/login")

          existing_user.id == current_user.id ->
            case Memberships.get_membership(existing_user.id, tenant.id) do
              nil ->
                case Memberships.create_membership(%{
                       user_id: existing_user.id,
                       tenant_id: tenant.id,
                       role: invite.role
                     }) do
                  {:ok, _} -> :ok
                  {:error, _} -> :ok
                end

                Invites.accept_invite(invite)

              _ ->
                :ok
            end

            conn
            |> put_flash(:info, gettext("Welcome to %{name}!", name: tenant.name))
            |> redirect(to: "/#{tenant.slug}/app")

          true ->
            conn
            |> assign(:invite, invite)
            |> assign(:tenant, tenant)
            |> assign(:existing_user, existing_user)
            |> assign(:current_user, current_user)
            |> assign(:needs_login, false)
            |> assign(:needs_accept, false)
            |> assign(:mismatch, true)
            |> render("show.html")
        end
    end
  end
end
