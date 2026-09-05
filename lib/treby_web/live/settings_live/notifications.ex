defmodule TrebyWeb.SettingsLive.Notifications do
  use TrebyWeb, :live_view

  alias Treby.{Accounts, Tenants, Notifications}

  def mount(_params, session, socket) do
    socket = set_locale_from_session(socket, session)

    {user, tenant} =
      cond do
        socket.assigns[:current_user] && socket.assigns[:current_tenant] ->
          {socket.assigns.current_user, socket.assigns.current_tenant}

        session["user_id"] && session["tenant_id"] ->
          {Accounts.get_user!(session["user_id"]), Tenants.get_tenant!(session["tenant_id"])}

        session["user_id"] ->
          u = Accounts.get_user!(session["user_id"])

          case Treby.Memberships.list_tenants_for_user(u.id) do
            [%{tenant: t} | _] -> {u, t}
            [] -> {u, nil}
          end

        true ->
          {nil, nil}
      end

    preferences = Notifications.notification_preferences(tenant)

    {:ok,
     socket
     |> assign(current_user: user, current_tenant: tenant)
     |> assign(preferences: preferences)}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_user} locale={@locale}>
      <div class="p-8">
        <div class="mb-8">
          <.button variant="ghost" size="sm" navigate={~p"/app/settings"}>
            &larr; {gettext("Back to Settings")}
          </.button>
          <h1 class="text-2xl font-bold mt-2">{gettext("Notification Preferences")}</h1>
          <p class="mt-1 text-zinc-500 dark:text-zinc-400">
            {gettext("Configure which email notifications are sent automatically")}
          </p>
        </div>

        <div class="bg-white dark:bg-zinc-800 rounded-xl border border-zinc-200 dark:border-zinc-700 shadow-sm overflow-hidden">
          <div class="divide-y divide-zinc-200 dark:divide-zinc-700">
            <div class="p-6">
              <div class="flex items-center justify-between">
                <div>
                  <h3 class="text-sm font-medium text-zinc-900 dark:text-zinc-100">
                    {gettext("Stage Change Notifications")}
                  </h3>
                  <p class="mt-1 text-sm text-zinc-400 dark:text-zinc-500">
                    {gettext(
                      "Send email to candidates when their application moves to a new pipeline stage"
                    )}
                  </p>
                </div>
                <button
                  phx-click="toggle_preference"
                  phx-value-key="stage_change_candidate"
                  class={[
                    "relative inline-flex h-6 w-11 shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors duration-200 ease-in-out focus:outline-none focus:ring-2 focus:ring-primary focus:ring-offset-2",
                    @preferences["stage_change_candidate"] && "bg-primary",
                    !@preferences["stage_change_candidate"] && "bg-zinc-200 dark:bg-zinc-700"
                  ]}
                  role="switch"
                  aria-checked={to_string(@preferences["stage_change_candidate"])}
                >
                  <span class={[
                    "pointer-events-none inline-block h-5 w-5 rounded-full bg-white dark:bg-zinc-800 shadow ring-0 transition duration-200 ease-in-out",
                    @preferences["stage_change_candidate"] && "translate-x-5",
                    !@preferences["stage_change_candidate"] && "translate-x-0"
                  ]} />
                </button>
              </div>
            </div>

            <div class="p-6">
              <div class="flex items-center justify-between">
                <div>
                  <h3 class="text-sm font-medium text-zinc-900 dark:text-zinc-100">
                    {gettext("Application Confirmation")}
                  </h3>
                  <p class="mt-1 text-sm text-zinc-400 dark:text-zinc-500">
                    {gettext(
                      "Send confirmation email to candidates after they apply via the career page"
                    )}
                  </p>
                </div>
                <button
                  phx-click="toggle_preference"
                  phx-value-key="new_application_candidate"
                  class={[
                    "relative inline-flex h-6 w-11 shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors duration-200 ease-in-out focus:outline-none focus:ring-2 focus:ring-primary focus:ring-offset-2",
                    @preferences["new_application_candidate"] && "bg-primary",
                    !@preferences["new_application_candidate"] && "bg-zinc-200 dark:bg-zinc-700"
                  ]}
                  role="switch"
                  aria-checked={to_string(@preferences["new_application_candidate"])}
                >
                  <span class={[
                    "pointer-events-none inline-block h-5 w-5 rounded-full bg-white dark:bg-zinc-800 shadow ring-0 transition duration-200 ease-in-out",
                    @preferences["new_application_candidate"] && "translate-x-5",
                    !@preferences["new_application_candidate"] && "translate-x-0"
                  ]} />
                </button>
              </div>
            </div>

            <div class="p-6">
              <div class="flex items-center justify-between">
                <div>
                  <h3 class="text-sm font-medium text-zinc-900 dark:text-zinc-100">
                    {gettext("New Application Alerts")}
                  </h3>
                  <p class="mt-1 text-sm text-zinc-400 dark:text-zinc-500">
                    {gettext("Notify admins when a new application is submitted for any job")}
                  </p>
                </div>
                <button
                  phx-click="toggle_preference"
                  phx-value-key="new_application_team"
                  class={[
                    "relative inline-flex h-6 w-11 shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors duration-200 ease-in-out focus:outline-none focus:ring-2 focus:ring-primary focus:ring-offset-2",
                    @preferences["new_application_team"] && "bg-primary",
                    !@preferences["new_application_team"] && "bg-zinc-200 dark:bg-zinc-700"
                  ]}
                  role="switch"
                  aria-checked={to_string(@preferences["new_application_team"])}
                >
                  <span class={[
                    "pointer-events-none inline-block h-5 w-5 rounded-full bg-white dark:bg-zinc-800 shadow ring-0 transition duration-200 ease-in-out",
                    @preferences["new_application_team"] && "translate-x-5",
                    !@preferences["new_application_team"] && "translate-x-0"
                  ]} />
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  def handle_event("toggle_preference", %{"key" => key}, socket) do
    current_value = Map.get(socket.assigns.preferences, key, true)
    new_value = !current_value

    case Notifications.set_notification_preference(
           socket.assigns.current_tenant,
           key,
           new_value
         ) do
      {:ok, _tenant} ->
        preferences = Map.put(socket.assigns.preferences, key, new_value)

        {:noreply,
         socket
         |> assign(preferences: preferences)
         |> put_flash(:info, gettext("Notification preference updated"))}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, gettext("Failed to update preference"))}
    end
  end
end
