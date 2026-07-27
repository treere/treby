defmodule TrebyWeb.SettingsLive.Team do
  use TrebyWeb, :live_view

  alias Treby.{Accounts, Tenants, Invites}

  def mount(_params, session, socket) do
    socket = set_locale_from_session(socket, session)
    user = Accounts.get_user!(session["user_id"])
    tenant = Tenants.get_tenant!(session["tenant_id"])
    users = Accounts.list_users(tenant.id)
    invites = Invites.list_invites(tenant.id)

    {:ok,
     socket
     |> assign(current_user: user, current_tenant: tenant)
     |> assign(users: users)
     |> assign(invites: invites)
     |> assign(show_invite_form: false)
     |> assign(invite_form: to_form(%{"email" => "", "role" => "member"}))
     |> assign(confirm_delete: nil)
     |> assign(confirm_delete_type: nil)}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_user} locale={@locale}>
      <div class="p-8">
        <div class="flex justify-between items-center mb-8">
          <div>
            <.link navigate={~p"/app/settings"} class="text-blue-600 hover:text-blue-900 text-sm">
              &larr; Back to Settings
            </.link>
            <h1 class="text-2xl font-bold mt-2">Team Management</h1>
            <p class="mt-1 text-gray-600">Manage your team members</p>
          </div>
          <button
            phx-click="show_invite_form"
            class="bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700"
          >
            + Invite Member
          </button>
        </div>

        <div :if={@show_invite_form} class="mb-8 p-6 bg-white rounded-lg shadow">
          <h2 class="text-lg font-semibold mb-4">Invite Team Member</h2>
          <.form
            for={@invite_form}
            id="invite-form"
            phx-submit="send_invite"
            class="flex gap-4 items-end"
          >
            <.input
              field={@invite_form[:email]}
              type="email"
              label="Email"
              placeholder="colleague@company.com"
            />
            <.input
              field={@invite_form[:role]}
              type="select"
              label="Role"
              options={[{"Member", "member"}, {"Admin", "admin"}]}
            />
            <div class="flex gap-2">
              <.button type="submit">Send Invite</.button>
              <.button type="button" phx-click="cancel_invite" class="bg-gray-500">Cancel</.button>
            </div>
          </.form>
        </div>

        <div class="bg-white rounded-lg shadow overflow-hidden mb-8">
          <div class="px-6 py-4 border-b">
            <h2 class="text-lg font-semibold">Team Members</h2>
          </div>
          <table class="min-w-full divide-y divide-gray-200">
            <thead class="bg-gray-50">
              <tr>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Name
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Email
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Role
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Actions
                </th>
              </tr>
            </thead>
            <tbody class="bg-white divide-y divide-gray-200">
              <tr :for={user <- @users} class="hover:bg-gray-50">
                <td class="px-6 py-4 whitespace-nowrap font-medium text-gray-900">{user.name}</td>
                <td class="px-6 py-4 whitespace-nowrap text-gray-600">{user.email}</td>
                <td class="px-6 py-4 whitespace-nowrap">
                  <span class={"px-2 inline-flex text-xs leading-5 font-semibold rounded-full #{if user.role == "admin", do: "bg-purple-100 text-purple-800", else: "bg-gray-100 text-gray-800"}"}>
                    {user.role}
                  </span>
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-sm">
                  <%= if user.id != @current_user.id do %>
                    <button
                      phx-click="confirm_delete"
                      phx-value-id={user.id}
                      phx-value-title="Remove team member"
                      phx-value-message="Are you sure you want to remove this team member? They will lose access to the account."
                      class="text-red-600 hover:text-red-900"
                    >
                      Remove
                    </button>
                  <% else %>
                    <span class="text-gray-400">You</span>
                  <% end %>
                </td>
              </tr>
            </tbody>
          </table>
        </div>

        <div :if={@invites != []} class="bg-white rounded-lg shadow overflow-hidden">
          <div class="px-6 py-4 border-b">
            <h2 class="text-lg font-semibold">Pending Invites</h2>
          </div>
          <table class="min-w-full divide-y divide-gray-200">
            <thead class="bg-gray-50">
              <tr>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Email
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Role
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Expires
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Actions
                </th>
              </tr>
            </thead>
            <tbody class="bg-white divide-y divide-gray-200">
              <tr :for={invite <- @invites} class="hover:bg-gray-50">
                <td class="px-6 py-4 whitespace-nowrap text-gray-900">{invite.email}</td>
                <td class="px-6 py-4 whitespace-nowrap">
                  <span class={"px-2 inline-flex text-xs leading-5 font-semibold rounded-full #{if invite.role == "admin", do: "bg-purple-100 text-purple-800", else: "bg-gray-100 text-gray-800"}"}>
                    {invite.role}
                  </span>
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                  {Calendar.strftime(invite.expires_at, "%b %d, %Y")}
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-sm">
                  <button
                    phx-click="confirm_delete"
                    phx-value-id={invite.id}
                    phx-value-title="Revoke invitation"
                    phx-value-message="Are you sure you want to revoke this invitation? The invitee will no longer be able to join."
                    class="text-red-600 hover:text-red-900"
                  >
                    Revoke
                  </button>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </Layouts.app>
    <.confirm_modal confirm_delete={@confirm_delete} on_confirm="do_confirm_delete" />
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
         |> put_flash(:info, "Invite sent to #{email}")}

      {:error, :unauthorized} ->
        {:noreply, put_flash(socket, :error, "Only admins can invite team members")}

      {:error, _changeset} ->
        {:noreply,
         put_flash(socket, :error, "Failed to send invite. Email may already be invited.")}
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
             |> put_flash(:info, "Team member removed")}

          {:error, _} ->
            {:noreply,
             socket
             |> assign(confirm_delete: nil, confirm_delete_type: nil)
             |> put_flash(:error, "Failed to remove team member")}
        end

      "invite" ->
        invite = Invites.get_invite_by_token(id) || %Invites.Invite{id: id}

        case Invites.delete_invite(invite, socket.assigns.current_user) do
          {:ok, _} ->
            invites = Invites.list_invites(socket.assigns.current_tenant.id)

            {:noreply,
             socket
             |> assign(invites: invites, confirm_delete: nil, confirm_delete_type: nil)
             |> put_flash(:info, "Invite revoked")}

          {:error, :unauthorized} ->
            {:noreply,
             socket
             |> assign(confirm_delete: nil, confirm_delete_type: nil)
             |> put_flash(:error, "Only admins can revoke invites")}

          {:error, _} ->
            {:noreply,
             socket
             |> assign(confirm_delete: nil, confirm_delete_type: nil)
             |> put_flash(:error, "Failed to revoke invite")}
        end

      _ ->
        {:noreply, socket |> assign(confirm_delete: nil, confirm_delete_type: nil)}
    end
  end
end
