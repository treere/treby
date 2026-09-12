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
    retention = Notifications.get_retention_days(tenant)

    {:ok,
     socket
     |> assign(current_user: user, current_tenant: tenant)
     |> assign(preferences: preferences, retention: retention)}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_user} locale={@locale}>
      <div class="p-8">
        <div class="mb-8">
          <.button variant="ghost" size="sm" navigate={~p"/app/settings"}>
            &larr; {gettext("Back to Settings")}
          </.button>
          <h1 class="text-2xl font-bold text-zinc-900 dark:text-zinc-100 mt-2">
            {gettext("Notification Preferences")}
          </h1>
          <p class="mt-1 text-zinc-500 dark:text-zinc-400">
            {gettext("Configure which notifications are sent via email and in-app inbox")}
          </p>
        </div>

        <div class="bg-white dark:bg-zinc-800 rounded-xl border border-zinc-200 dark:border-zinc-700 shadow-sm overflow-hidden mb-6">
          <div class="p-6">
            <div class="flex items-center justify-between">
              <div>
                <h3 class="text-sm font-medium text-zinc-900 dark:text-zinc-100">
                  {gettext("Retention of read notifications")}
                </h3>
                <p class="mt-1 text-sm text-zinc-500 dark:text-zinc-400">
                  {gettext(
                    "How long read notifications are kept before automatic deletion (unread are never deleted)"
                  )}
                </p>
              </div>
              <form id="retention-form" phx-change="set_retention">
                <select
                  name="retention"
                  class="rounded-lg border border-zinc-200 dark:border-zinc-700 bg-white dark:bg-zinc-800 px-3 py-2 text-sm"
                >
                  <option value="7" selected={@retention == 7}>7 {gettext("days")}</option>
                  <option value="14" selected={@retention == 14}>14 {gettext("days")}</option>
                  <option value="30" selected={@retention == 30}>30 {gettext("days")}</option>
                  <option value="60" selected={@retention == 60}>60 {gettext("days")}</option>
                  <option value="90" selected={@retention == 90}>90 {gettext("days")}</option>
                </select>
              </form>
            </div>
          </div>
        </div>

        <div class="bg-white dark:bg-zinc-800 rounded-xl border border-zinc-200 dark:border-zinc-700 shadow-sm overflow-hidden">
          <div class="divide-y divide-zinc-200 dark:divide-zinc-700">
            <.pref_row
              title={gettext("Stage Change Notifications")}
              desc={gettext("Notify candidates when their application moves to a new pipeline stage")}
              pref_key="stage_change_candidate"
              pref={@preferences["stage_change_candidate"]}
            />
            <.pref_row
              title={gettext("Application Confirmation")}
              desc={gettext("Send confirmation to candidates after they apply via the career page")}
              pref_key="new_application_candidate"
              pref={@preferences["new_application_candidate"]}
            />
            <.pref_row
              title={gettext("New Application Alerts")}
              desc={gettext("Notify team when a new application is submitted for any job")}
              pref_key="new_application_team"
              pref={@preferences["new_application_team"]}
            />
            <.pref_row
              title={gettext("Interview Reminders")}
              desc={gettext("Reminders for upcoming interviews")}
              pref_key="interview_reminder"
              pref={@preferences["interview_reminder"]}
            />
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  attr :title, :string, required: true
  attr :desc, :string, required: true
  attr :pref_key, :string, required: true
  attr :pref, :map, required: true

  defp pref_row(assigns) do
    ~H"""
    <div class="p-6">
      <div class="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <div class="flex-1">
          <h3 class="text-sm font-medium text-zinc-900 dark:text-zinc-100">{@title}</h3>
          <p class="mt-1 text-sm text-zinc-500 dark:text-zinc-400">{@desc}</p>
        </div>
        <div class="flex items-center gap-6">
          <div class="flex items-center gap-2">
            <span class="text-xs font-medium text-zinc-500 dark:text-zinc-400">{gettext("Email")}</span>
            <button
              phx-click="toggle_preference"
              phx-value-key={@pref_key}
              phx-value-channel="email"
              class={[
                "relative inline-flex h-6 w-11 shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors duration-200 ease-in-out focus:outline-none focus:ring-2 focus:ring-orange-500 focus:ring-offset-2",
                @pref["email"] && "bg-orange-600",
                !@pref["email"] && "bg-zinc-200 dark:bg-zinc-700"
              ]}
              role="switch"
              aria-checked={to_string(@pref["email"])}
            >
              <span class={[
                "pointer-events-none inline-block h-5 w-5 rounded-full bg-white shadow ring-0 transition duration-200 ease-in-out",
                @pref["email"] && "translate-x-5",
                !@pref["email"] && "translate-x-0"
              ]} />
            </button>
          </div>
          <div class="flex items-center gap-2">
            <span class="text-xs font-medium text-zinc-500 dark:text-zinc-400">{gettext("In-app")}</span>
            <button
              phx-click="toggle_preference"
              phx-value-key={@pref_key}
              phx-value-channel="inbox"
              class={[
                "relative inline-flex h-6 w-11 shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors duration-200 ease-in-out focus:outline-none focus:ring-2 focus:ring-orange-500 focus:ring-offset-2",
                @pref["inbox"] && "bg-orange-600",
                !@pref["inbox"] && "bg-zinc-200 dark:bg-zinc-700"
              ]}
              role="switch"
              aria-checked={to_string(@pref["inbox"])}
            >
              <span class={[
                "pointer-events-none inline-block h-5 w-5 rounded-full bg-white shadow ring-0 transition duration-200 ease-in-out",
                @pref["inbox"] && "translate-x-5",
                !@pref["inbox"] && "translate-x-0"
              ]} />
            </button>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def handle_event("toggle_preference", %{"key" => key} = params, socket) do
    channel = Map.get(params, "channel", "email")

    case Notifications.toggle_notification_preference(
           socket.assigns.current_tenant.id,
           key,
           channel
         ) do
      {:ok, tenant, _new_value} ->
        {:noreply,
         socket
         |> assign(current_tenant: tenant)
         |> assign(preferences: Notifications.notification_preferences(tenant))
         |> assign(retention: Notifications.get_retention_days(tenant))
         |> put_flash(:info, gettext("Notification preference updated"))}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, gettext("Failed to update preference"))}
    end
  end

  def handle_event("set_retention", %{"retention" => val}, socket) do
    case Notifications.set_retention_days(socket.assigns.current_tenant, val) do
      {:ok, tenant} ->
        {:noreply,
         socket
         |> assign(current_tenant: tenant)
         |> assign(retention: Notifications.get_retention_days(tenant))
         |> put_flash(:info, gettext("Retention updated"))}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, gettext("Invalid retention value"))}
    end
  end
end
