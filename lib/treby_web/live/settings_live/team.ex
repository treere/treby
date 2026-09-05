defmodule TrebyWeb.SettingsLive.Team do
  use TrebyWeb, :live_view

  alias Treby.{Accounts, Tenants, Invites}

  def mount(params, session, socket) do
    socket = set_locale_from_session(socket, session)
    # Support both slug and legacy session
    {user, tenant, membership} =
      if params["tenant_slug"] do
        slug = params["tenant_slug"]
        tenant = Tenants.get_tenant_by_slug(slug)
        user = Accounts.get_user!(session["user_id"])
        membership = Treby.Memberships.get_membership(user.id, tenant.id)
        {user, tenant, membership}
      else
        user = Accounts.get_user!(session["user_id"])
        tenant = Tenants.get_tenant!(session["tenant_id"])
        {user, tenant, nil}
      end

    # Prefer memberships list with roles
    memberships = Treby.Memberships.list_members_for_tenant(tenant.id)
    # Keep users assign for backwards compat, but also memberships
    users = Enum.map(memberships, & &1.user)
    invites = Invites.list_invites(tenant.id)

    {:ok,
     socket
     |> assign(current_user: user, current_tenant: tenant, current_membership: membership)
     |> assign(memberships: memberships, users: users)
     |> assign(invites: invites)
     |> assign(show_invite_form: false)
     |> assign(invite_form: to_form(%{"email" => "", "role" => "member"}))
     |> assign(confirm_delete: nil)
     |> assign(confirm_delete_type: nil)}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app
      flash={@flash}
      current_scope={@current_user}
      locale={@locale}
      current_tenant={@current_tenant}
      current_membership={@current_membership}
      available_tenants={assigns[:available_tenants] || []}
    >
      <div class="p-8">
        <div class="flex justify-between items-center mb-8">
          <div>
            <.link
              navigate={"/#{@current_tenant.slug}/app/settings"}
              class="text-blue-600 hover:text-blue-900 text-sm"
            >
              &larr; Back to Settings
            </.link>
            <h1 class="text-2xl font-bold mt-2">{gettext("Team Management")}</h1>
            <p class="mt-1 text-zinc-500 dark:text-zinc-400">{gettext("Manage your team members")}</p>
          </div>
          <.button variant="primary" phx-click="show_invite_form">
            + Invite Member
          </.button>
        </div>

        <div
          :if={@show_invite_form}
          class="mb-8 p-6 bg-white dark:bg-zinc-800 rounded-xl border border-zinc-200 dark:border-zinc-700 shadow-sm"
        >
          <h2 class="text-lg font-semibold mb-4">{gettext("Invite Team Member")}</h2>
          <.form
            for={@invite_form}
            id="invite-form"
            phx-submit="send_invite"
            class="flex gap-4 items-end"
          >
            <.input
              field={@invite_form[:email]}
              type="email"
              label={gettext("Email")}
              placeholder="colleague@company.com"
            />
            <.input
              field={@invite_form[:role]}
              type="select"
              label={gettext("Role")}
              options={[{"Member", "member"}, {"Admin", "admin"}]}
            />
            <div class="flex gap-2">
              <.button type="submit">{gettext("Send Invite")}</.button>
              <.button type="button" variant="ghost" phx-click="cancel_invite">
                {gettext("Cancel")}
              </.button>
            </div>
          </.form>
        </div>

        <div class="bg-white dark:bg-zinc-800 rounded-xl border border-zinc-200 dark:border-zinc-700 shadow-sm overflow-hidden mb-8">
          <div class="px-6 py-4 border-b">
            <h2 class="text-lg font-semibold">{gettext("Team Members")}</h2>
          </div>
          <table class="min-w-full divide-y divide-zinc-100 dark:divide-zinc-700">
            <thead class="bg-zinc-50 dark:bg-zinc-800">
              <tr>
                <th class="px-6 py-3 text-left text-xs font-medium text-zinc-400 dark:text-zinc-500 uppercase tracking-wider">
                  {gettext("Name")}
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-zinc-400 dark:text-zinc-500 uppercase tracking-wider">
                  {gettext("Email")}
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-zinc-400 dark:text-zinc-500 uppercase tracking-wider">
                  {gettext("Role")}
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-zinc-400 dark:text-zinc-500 uppercase tracking-wider">
                  {gettext("Actions")}
                </th>
              </tr>
            </thead>
            <tbody class="bg-white dark:bg-zinc-800 divide-y divide-zinc-100 dark:divide-zinc-700">
              <tr :for={user <- @users} class="hover:bg-zinc-50 dark:bg-zinc-800">
                <td class="px-6 py-4 whitespace-nowrap font-medium text-zinc-900 dark:text-zinc-100">
                  {user.name}
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-zinc-500 dark:text-zinc-400">
                  {user.email}
                </td>
                <td class="px-6 py-4 whitespace-nowrap">
                  <% member = Enum.find(@memberships, &(&1.user_id == user.id)) %>
                  <span class={"px-2 inline-flex text-xs leading-5 font-semibold rounded-full #{if member && member.role == "admin", do: "bg-purple-100 text-purple-800", else: "bg-zinc-50 dark:bg-zinc-800 text-zinc-900 dark:text-zinc-100/90"}"}>
                    {member && member.role}
                  </span>
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-sm">
                  <%= if user.id != @current_user.id do %>
                    <button
                      phx-click="confirm_delete"
                      phx-value-id={user.id}
                      phx-value-title={gettext("Remove team member")}
                      phx-value-message={
                        gettext(
                          "Are you sure you want to remove this team member? They will lose access to the account."
                        )
                      }
                      class="text-red-600 hover:text-red-900"
                    >
                      {gettext("Remove")}
                    </button>
                  <% else %>
                    <span class="text-zinc-400 dark:text-zinc-500">{gettext("You")}</span>
                  <% end %>
                </td>
              </tr>
            </tbody>
          </table>
        </div>

        <div
          :if={@invites != []}
          class="bg-white dark:bg-zinc-800 rounded-xl border border-zinc-200 dark:border-zinc-700 shadow-sm overflow-hidden"
        >
          <div class="px-6 py-4 border-b">
            <h2 class="text-lg font-semibold">{gettext("Pending Invites")}</h2>
          </div>
          <table class="min-w-full divide-y divide-zinc-100 dark:divide-zinc-700">
            <thead class="bg-zinc-50 dark:bg-zinc-800">
              <tr>
                <th class="px-6 py-3 text-left text-xs font-medium text-zinc-400 dark:text-zinc-500 uppercase tracking-wider">
                  {gettext("Email")}
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-zinc-400 dark:text-zinc-500 uppercase tracking-wider">
                  {gettext("Role")}
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-zinc-400 dark:text-zinc-500 uppercase tracking-wider">
                  {gettext("Expires")}
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-zinc-400 dark:text-zinc-500 uppercase tracking-wider">
                  {gettext("Actions")}
                </th>
              </tr>
            </thead>
            <tbody class="bg-white dark:bg-zinc-800 divide-y divide-zinc-100 dark:divide-zinc-700">
              <tr :for={invite <- @invites} class="hover:bg-zinc-50 dark:bg-zinc-800">
                <td class="px-6 py-4 whitespace-nowrap text-zinc-900 dark:text-zinc-100">
                  {invite.email}
                </td>
                <td class="px-6 py-4 whitespace-nowrap">
                  <span class={"px-2 inline-flex text-xs leading-5 font-semibold rounded-full #{if invite.role == "admin", do: "bg-purple-100 text-purple-800", else: "bg-zinc-50 dark:bg-zinc-800 text-zinc-900 dark:text-zinc-100/90"}"}>
                    {invite.role}
                  </span>
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-zinc-400 dark:text-zinc-500">
                  {Calendar.strftime(invite.expires_at, "%b %d, %Y")}
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-sm">
                  <button
                    phx-click="confirm_delete"
                    phx-value-id={invite.id}
                    phx-value-title={gettext("Revoke invitation")}
                    phx-value-message={
                      gettext(
                        "Are you sure you want to revoke this invitation? The invitee will no longer be able to join."
                      )
                    }
                    class="text-red-600 hover:text-red-900"
                  >
                    {gettext("Revoke")}
                  </button>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </Layouts.app>
    <.confirm_dialog
      id="confirm-team"
      show={@confirm_delete != nil}
      title={@confirm_delete && @confirm_delete.title}
      message={@confirm_delete && @confirm_delete.message}
      confirm_label="Delete"
      confirm_variant="danger"
      on_confirm="do_confirm_delete"
      on_cancel="cancel_delete"
      extra_attrs={(@confirm_delete && %{id: @confirm_delete.id}) || %{}}
    />
    """
  end

  def handle_event("show_invite_form", _, socket) do
    {:noreply, assign(socket, show_invite_form: true)}
  end

  def handle_event("cancel_invite", _, socket) do
    {:noreply, assign(socket, show_invite_form: false)}
  end

  def handle_event("send_invite", %{"email" => email, "role" => role}, socket) do
    attrs = %{
      "email" => email,
      "role" => role,
      "tenant_id" => socket.assigns.current_tenant.id
    }

    case Invites.create_invite(attrs, socket.assigns.current_user) do
      {:ok, _invite} ->
        invites = Invites.list_invites(socket.assigns.current_tenant.id)

        {:noreply,
         socket
         |> assign(invites: invites, show_invite_form: false)
         |> put_flash(:info, gettext("Invite sent to %{email}", email: email))}

      {:error, :unauthorized} ->
        {:noreply, put_flash(socket, :error, gettext("Only admins can invite team members"))}

      {:error, _changeset} ->
        {:noreply,
         put_flash(
           socket,
           :error,
           gettext("Failed to send invite. Email may already be invited.")
         )}
    end
  end

  def handle_event(
        "confirm_delete",
        %{"id" => id, "title" => title, "message" => message},
        socket
      ) do
    type =
      cond do
        String.contains?(title, "team member") -> "user"
        String.contains?(title, "invitation") -> "invite"
        true -> nil
      end

    {:noreply,
     socket
     |> assign(confirm_delete: %{id: id, title: title, message: message})
     |> assign(confirm_delete_type: type)}
  end

  def handle_event("cancel_delete", _params, socket) do
    {:noreply, socket |> assign(confirm_delete: nil) |> assign(confirm_delete_type: nil)}
  end

  def handle_event("do_confirm_delete", %{"id" => id}, socket) do
    case socket.assigns.confirm_delete_type do
      "user" ->
        user = Accounts.get_user!(id)

        case Accounts.remove_user_from_tenant(user, socket.assigns.current_user) do
          {:ok, _} ->
            users = Accounts.list_users(socket.assigns.current_tenant.id)

            {:noreply,
             socket
             |> assign(users: users, confirm_delete: nil, confirm_delete_type: nil)
             |> put_flash(:info, gettext("Team member removed"))}

          {:error, _} ->
            {:noreply,
             socket
             |> assign(confirm_delete: nil, confirm_delete_type: nil)
             |> put_flash(:error, gettext("Failed to remove team member"))}
        end

      "invite" ->
        invite = Invites.get_invite_by_token(id) || %Invites.Invite{id: id}

        case Invites.delete_invite(invite, socket.assigns.current_user) do
          {:ok, _} ->
            invites = Invites.list_invites(socket.assigns.current_tenant.id)

            {:noreply,
             socket
             |> assign(invites: invites, confirm_delete: nil, confirm_delete_type: nil)
             |> put_flash(:info, gettext("Invite revoked"))}

          {:error, :unauthorized} ->
            {:noreply,
             socket
             |> assign(confirm_delete: nil, confirm_delete_type: nil)
             |> put_flash(:error, gettext("Only admins can revoke invites"))}

          {:error, _} ->
            {:noreply,
             socket
             |> assign(confirm_delete: nil, confirm_delete_type: nil)
             |> put_flash(:error, gettext("Failed to revoke invite"))}
        end

      _ ->
        {:noreply, socket |> assign(confirm_delete: nil, confirm_delete_type: nil)}
    end
  end
end
