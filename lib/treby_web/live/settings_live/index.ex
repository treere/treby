defmodule TrebyWeb.SettingsLive.Index do
  use TrebyWeb, :live_view

  alias Treby.{Accounts, Tenants}

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

    {:ok, assign(socket, current_user: user, current_tenant: tenant)}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_user} locale={@locale}>
      <div class="p-8">
        <.page_header
          title={gettext("Settings")}
          subtitle={
            if @current_tenant do
              gettext("Company settings for %{name}", name: @current_tenant.name)
            else
              gettext("Company settings")
            end
          }
        />

        <div class="mt-8 grid grid-cols-1 md:grid-cols-2 gap-6">
          <.link
            :if={@current_membership.role == "admin"}
            navigate={~p"/app/settings/pipeline"}
            class="card bg-white dark:bg-zinc-800 shadow p-6 hover:shadow-md transition-shadow block"
          >
            <h2 class="text-lg font-semibold text-zinc-900 dark:text-zinc-100">
              {gettext("Pipeline Stages")}
            </h2>
            <p class="mt-2 text-sm text-zinc-500 dark:text-zinc-400">
              {gettext("Customize your hiring pipeline stages")}
            </p>
          </.link>

          <.link
            navigate={~p"/app/settings/branding"}
            class="card bg-white dark:bg-zinc-800 shadow p-6 hover:shadow-md transition-shadow block"
          >
            <h2 class="text-lg font-semibold text-zinc-900 dark:text-zinc-100">
              {gettext("Branding")}
            </h2>
            <p class="mt-2 text-sm text-zinc-500 dark:text-zinc-400">
              {gettext("Customize career page appearance")}
            </p>
          </.link>

          <.link
            :if={@current_membership.role == "admin"}
            navigate={~p"/app/settings/team"}
            class="card bg-white dark:bg-zinc-800 shadow p-6 hover:shadow-md transition-shadow block"
          >
            <h2 class="text-lg font-semibold text-zinc-900 dark:text-zinc-100">{gettext("Team")}</h2>
            <p class="mt-2 text-sm text-zinc-500 dark:text-zinc-400">
              {gettext("Manage team members and invites")}
            </p>
          </.link>

          <.link
            :if={@current_membership.role == "admin"}
            navigate={~p"/app/settings/fields"}
            class="card bg-white dark:bg-zinc-800 shadow p-6 hover:shadow-md transition-shadow block"
          >
            <h2 class="text-lg font-semibold text-zinc-900 dark:text-zinc-100">
              {gettext("Custom Fields")}
            </h2>
            <p class="mt-2 text-sm text-zinc-500 dark:text-zinc-400">
              {gettext("Define custom fields for candidates and jobs")}
            </p>
          </.link>

          <.link
            :if={@current_membership.role == "admin"}
            navigate={~p"/app/settings/scorecards"}
            class="card bg-white dark:bg-zinc-800 shadow p-6 hover:shadow-md transition-shadow block"
          >
            <h2 class="text-lg font-semibold text-zinc-900 dark:text-zinc-100">
              {gettext("Scorecard Templates")}
            </h2>
            <p class="mt-2 text-sm text-zinc-500 dark:text-zinc-400">
              {gettext("Define evaluation criteria for interviews")}
            </p>
          </.link>

          <.link
            :if={@current_membership.role == "admin"}
            navigate={~p"/app/settings/emails"}
            class="card bg-white dark:bg-zinc-800 shadow p-6 hover:shadow-md transition-shadow block"
          >
            <h2 class="text-lg font-semibold text-zinc-900 dark:text-zinc-100">
              {gettext("Message Templates")}
            </h2>
            <p class="mt-2 text-sm text-zinc-500 dark:text-zinc-400">
              {gettext("Configure message templates for stage transitions")}
            </p>
          </.link>

          <.link
            :if={@current_membership.role == "admin"}
            navigate={~p"/app/settings/notifications"}
            class="card bg-white dark:bg-zinc-800 shadow p-6 hover:shadow-md transition-shadow block"
          >
            <h2 class="text-lg font-semibold text-zinc-900 dark:text-zinc-100">
              {gettext("Notifications")}
            </h2>
            <p class="mt-2 text-sm text-zinc-500 dark:text-zinc-400">
              {gettext("Configure automated email notifications")}
            </p>
          </.link>

          <.link
            :if={@current_membership.role == "admin"}
            navigate={~p"/app/settings/sources"}
            class="card bg-white dark:bg-zinc-800 shadow p-6 hover:shadow-md transition-shadow block"
          >
            <h2 class="text-lg font-semibold text-zinc-900 dark:text-zinc-100">
              {gettext("Sources")}
            </h2>
            <p class="mt-2 text-sm text-zinc-500 dark:text-zinc-400">
              {gettext("Manage how candidates find you")}
            </p>
          </.link>

          <.link
            navigate={~p"/app/settings/calendar"}
            class="card bg-white dark:bg-zinc-800 shadow p-6 hover:shadow-md transition-shadow block"
          >
            <h2 class="text-lg font-semibold text-zinc-900 dark:text-zinc-100">
              {gettext("Calendar")}
            </h2>
            <p class="mt-2 text-sm text-zinc-500 dark:text-zinc-400">
              {gettext("Connect Google Calendar for interview scheduling")}
            </p>
          </.link>

          <.link
            navigate={~p"/app/settings/availability"}
            class="card bg-white dark:bg-zinc-800 shadow p-6 hover:shadow-md transition-shadow block"
          >
            <h2 class="text-lg font-semibold text-zinc-900 dark:text-zinc-100">
              {gettext("Availability")}
            </h2>
            <p class="mt-2 text-sm text-zinc-500 dark:text-zinc-400">
              {gettext("Set your available hours for interviews")}
            </p>
          </.link>

          <.link
            navigate={~p"/app/settings/language"}
            class="card bg-white dark:bg-zinc-800 shadow p-6 hover:shadow-md transition-shadow block"
          >
            <h2 class="text-lg font-semibold text-zinc-900 dark:text-zinc-100">
              {gettext("Language")}
            </h2>
            <p class="mt-2 text-sm text-zinc-500 dark:text-zinc-400">
              {gettext("Set your preferred language")}
            </p>
          </.link>

          <.link
            :if={@current_membership.role == "admin"}
            navigate={~p"/app/settings/audit-log"}
            class="card bg-white dark:bg-zinc-800 shadow p-6 hover:shadow-md transition-shadow block"
            id="settings-audit-log"
          >
            <h2 class="text-lg font-semibold text-zinc-900 dark:text-zinc-100">
              {gettext("Audit Log")}
            </h2>
            <p class="mt-2 text-sm text-zinc-500 dark:text-zinc-400">
              {gettext("Immutable history of all changes in this workspace")}
            </p>
          </.link>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
