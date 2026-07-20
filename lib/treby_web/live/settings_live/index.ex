defmodule TrebyWeb.SettingsLive.Index do
  use TrebyWeb, :live_view

  alias Treby.{Accounts, Tenants}

  def mount(_params, session, socket) do
    user = Accounts.get_user!(session["user_id"])
    tenant = Tenants.get_tenant!(session["tenant_id"])

    {:ok, assign(socket, current_user: user, current_tenant: tenant)}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_user}>
      <div class="p-8">
        <h1 class="text-2xl font-bold">Settings</h1>
        <p class="mt-2 text-gray-600">Company settings for {@current_tenant.name}</p>

        <div class="mt-8 grid grid-cols-1 md:grid-cols-2 gap-6">
          <.link
            navigate={~p"/app/settings/pipeline"}
            class="block bg-white rounded-lg shadow p-6 hover:shadow-md transition-shadow"
          >
            <h2 class="text-lg font-semibold text-gray-900">Pipeline Stages</h2>
            <p class="mt-2 text-sm text-gray-600">Customize your hiring pipeline stages</p>
          </.link>

          <.link
            navigate={~p"/app/settings/branding"}
            class="block bg-white rounded-lg shadow p-6 hover:shadow-md transition-shadow"
          >
            <h2 class="text-lg font-semibold text-gray-900">Branding</h2>
            <p class="mt-2 text-sm text-gray-600">Customize career page appearance</p>
          </.link>

          <.link
            navigate={~p"/app/settings/team"}
            class="block bg-white rounded-lg shadow p-6 hover:shadow-md transition-shadow"
          >
            <h2 class="text-lg font-semibold text-gray-900">Team</h2>
            <p class="mt-2 text-sm text-gray-600">Manage team members and invites</p>
          </.link>

          <.link
            navigate={~p"/app/settings/fields"}
            class="block bg-white rounded-lg shadow p-6 hover:shadow-md transition-shadow"
          >
            <h2 class="text-lg font-semibold text-gray-900">Custom Fields</h2>
            <p class="mt-2 text-sm text-gray-600">Define custom fields for candidates and jobs</p>
          </.link>

          <.link
            navigate={~p"/app/settings/calendar"}
            class="block bg-white rounded-lg shadow p-6 hover:shadow-md transition-shadow"
          >
            <h2 class="text-lg font-semibold text-gray-900">Calendar</h2>
            <p class="mt-2 text-sm text-gray-600">Connect Google Calendar for interview scheduling</p>
          </.link>

          <.link
            navigate={~p"/app/settings/availability"}
            class="block bg-white rounded-lg shadow p-6 hover:shadow-md transition-shadow"
          >
            <h2 class="text-lg font-semibold text-gray-900">Availability</h2>
            <p class="mt-2 text-sm text-gray-600">Set your available hours for interviews</p>
          </.link>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
