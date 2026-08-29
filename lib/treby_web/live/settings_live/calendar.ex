defmodule TrebyWeb.SettingsLive.Calendar do
  use TrebyWeb, :live_view

  alias Treby.{Accounts, Tenants, Calendar}

  def mount(_params, session, socket) do
    socket = set_locale_from_session(socket, session)
    user = Accounts.get_user!(session["user_id"])
    tenant = Tenants.get_tenant!(session["tenant_id"])
    connection = Calendar.get_connection(user.id, "google")

    {:ok,
     socket
     |> assign(current_user: user, current_tenant: tenant)
     |> assign(connection: connection)}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_user} locale={@locale}>
      <div class="p-8">
        <div class="mb-8">
          <.link navigate={~p"/app/settings"} class="text-blue-600 hover:text-blue-900 text-sm">
            &larr; Back to Settings
          </.link>
          <h1 class="text-2xl font-bold mt-2">Calendar Integration</h1>
          <p class="mt-1 text-base-content/70">
            Connect your Google Calendar to check availability and create interview events
          </p>
        </div>

        <div class="bg-base-100 rounded-lg shadow p-6">
          <%= if @connection do %>
            <div class="flex items-center justify-between">
              <div>
                <div class="flex items-center gap-2">
                  <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800">
                    Connected
                  </span>
                </div>
                <p class="mt-2 text-sm text-base-content/70">
                  Connected as <strong>{@connection.provider_email}</strong>
                </p>
                <p class="mt-1 text-xs text-base-content/40">
                  Connected {Elixir.Calendar.strftime(@connection.connected_at, "%B %d, %Y")}
                </p>
              </div>
              <.link
                href={~p"/auth/google"}
                class="inline-flex items-center px-4 py-2 border border-base-300 text-sm font-medium rounded-md text-base-content/80 bg-base-100 hover:bg-base-200"
              >
                Reconnect
              </.link>
            </div>

            <div class="mt-6 pt-6 border-t">
              <.link
                href="#"
                phx-click="disconnect"
                data-confirm="Are you sure you want to disconnect your Google Calendar?"
                class="text-red-600 hover:text-red-800 text-sm font-medium"
              >
                Disconnect Google Calendar
              </.link>
            </div>
          <% else %>
            <div class="text-center py-8">
              <.icon name="hero-calendar" class="mx-auto h-12 w-12 text-base-content/40" />
              <h3 class="mt-2 text-sm font-medium text-base-content">No calendar connected</h3>
              <p class="mt-1 text-sm text-base-content/50">
                Connect your Google Calendar to check availability against your calendar. Interview
                scheduling works even without it.
              </p>
              <div class="mt-6">
                <.link
                  href={~p"/auth/google"}
                  class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-blue-600 hover:bg-blue-700"
                >
                  <.icon name="hero-plus" class="mr-2 h-4 w-4" /> Connect Google Calendar
                </.link>
              </div>
            </div>
          <% end %>
        </div>
      </div>
    </Layouts.app>
    """
  end

  def handle_event("disconnect", _, socket) do
    Calendar.disconnect_google_user(socket.assigns.current_user.id)

    {:noreply,
     socket
     |> assign(connection: nil)
     |> put_flash(:info, "Google Calendar disconnected")}
  end
end
