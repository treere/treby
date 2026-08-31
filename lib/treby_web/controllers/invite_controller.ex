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
      nil -> redirect_invalid(conn)
      invite -> handle_create_with_user(conn, invite, user_params)
    end
  end

  # Handle accept without user params (for existing user same)
  def create(conn, %{"token" => token}) do
    case Invites.get_invite_by_token(token) do
      nil -> redirect_invalid(conn)
      invite -> handle_create_without_user(conn, invite)
    end
  end

  defp redirect_invalid(conn) do
    conn
    |> put_flash(:error, gettext("Invalid or expired invite link"))
    |> redirect(to: ~p"/login")
  end

  defp get_current_user(conn) do
    case get_session(conn, "user_id") do
      nil -> nil
      id -> Repo.get(User, id)
    end
  end

  defp handle_create_with_user(conn, invite, user_params) do
    tenant = Tenants.get_tenant!(invite.tenant_id)
    existing_user = Accounts.get_user_by_email(invite.email)
    current_user = get_current_user(conn)
    dispatch_create_with_user(conn, invite, tenant, existing_user, current_user, user_params)
  end

  defp dispatch_create_with_user(conn, invite, tenant, nil, _current, user_params) do
    create_new_identity(conn, invite, tenant, user_params)
  end

  defp dispatch_create_with_user(conn, invite, _tenant, _existing, nil, _params) do
    conn
    |> put_flash(
      :error,
      gettext("Please log in as %{email} to accept this invite", email: invite.email)
    )
    |> redirect(to: ~p"/login")
  end

  defp dispatch_create_with_user(conn, invite, tenant, existing, current, _params)
       when existing.id == current.id do
    ensure_membership(invite, existing.id, tenant.id, invite.role)

    conn
    |> put_flash(:info, gettext("Welcome to %{name}!", name: tenant.name))
    |> redirect(to: "/#{tenant.slug}/app")
  end

  defp dispatch_create_with_user(conn, invite, tenant, existing, current, _params) do
    conn
    |> assign(:invite, invite)
    |> assign(:tenant, tenant)
    |> assign(:existing_user, existing)
    |> assign(:current_user, current)
    |> assign(:needs_login, false)
    |> assign(:needs_accept, false)
    |> assign(:mismatch, true)
    |> put_flash(:error, gettext("You are logged in as a different user"))
    |> render("show.html")
  end

  defp create_new_identity(conn, invite, tenant, user_params) do
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

    handle_new_identity_result(conn, invite, tenant, result)
  end

  defp handle_new_identity_result(conn, invite, tenant, {:ok, user}) do
    ensure_membership(invite, user.id, tenant.id, invite.role)
    Invites.accept_invite(invite)

    conn
    |> put_session("user_id", user.id)
    |> delete_session("tenant_id")
    |> put_flash(:info, gettext("Welcome to %{name}!", name: tenant.name))
    |> redirect(to: "/#{tenant.slug}/app")
  end

  defp handle_new_identity_result(conn, invite, tenant, {:error, _changeset}) do
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

  defp handle_create_without_user(conn, invite) do
    tenant = Tenants.get_tenant!(invite.tenant_id)
    existing_user = Accounts.get_user_by_email(invite.email)
    current_user = get_current_user(conn)
    dispatch_create_without_user(conn, invite, tenant, existing_user, current_user)
  end

  defp dispatch_create_without_user(conn, invite, tenant, nil, _current) do
    conn
    |> assign(:invite, invite)
    |> assign(:tenant, tenant)
    |> assign(:existing_user, nil)
    |> assign(:needs_login, false)
    |> assign(:needs_accept, false)
    |> assign(:mismatch, false)
    |> render("show.html")
  end

  defp dispatch_create_without_user(conn, invite, _tenant, _existing, nil) do
    conn
    |> put_flash(
      :error,
      gettext("Please log in as %{email} to accept this invite", email: invite.email)
    )
    |> redirect(to: ~p"/login")
  end

  defp dispatch_create_without_user(conn, invite, tenant, existing, current)
       when existing.id == current.id do
    ensure_membership(invite, existing.id, tenant.id, invite.role)

    conn
    |> put_flash(:info, gettext("Welcome to %{name}!", name: tenant.name))
    |> redirect(to: "/#{tenant.slug}/app")
  end

  defp dispatch_create_without_user(conn, invite, tenant, existing, current) do
    conn
    |> assign(:invite, invite)
    |> assign(:tenant, tenant)
    |> assign(:existing_user, existing)
    |> assign(:current_user, current)
    |> assign(:needs_login, false)
    |> assign(:needs_accept, false)
    |> assign(:mismatch, true)
    |> render("show.html")
  end

  defp ensure_membership(invite, user_id, tenant_id, role) do
    case Memberships.get_membership(user_id, tenant_id) do
      nil ->
        case Memberships.create_membership(%{user_id: user_id, tenant_id: tenant_id, role: role}) do
          {:ok, _} -> :ok
          {:error, _} -> :ok
        end

        Invites.accept_invite(invite)

      _ ->
        :ok
    end
  end
end
