defmodule TrebyWeb.SettingsLive.Index do
  use TrebyWeb, :live_view

  alias Treby.{Accounts, Tenants}

  def mount(_params, session, socket) do
    socket = set_locale_from_session(socket, session)
    user = Accounts.get_user!(session["user_id"])
    tenant = Tenants.get_tenant!(session["tenant_id"])

    {:ok, assign(socket, current_user: user, current_tenant: tenant)}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_user} locale={@locale}>
      <div class="p-8">
        <h1 class="text-2xl font-bold">{gettext("Settings")}</h1>
        <p class="mt-2 text-base-content/70">
          {gettext("Company settings for")} {@current_tenant.name}
        </p>

        <div class="mt-8 grid grid-cols-1 md:grid-cols-2 gap-6">
          <.link
            :if={@current_user.role == "admin"}
            navigate={~p"/app/settings/pipeline"}
            class="block bg-base-100 rounded-lg shadow p-6 hover:shadow-md transition-shadow"
          >
            <h2 class="text-lg font-semibold text-base-content">{gettext("Pipeline Stages")}</h2>
            <p class="mt-2 text-sm text-base-content/70">
              {gettext("Customize your hiring pipeline stages")}
            </p>
          </.link>

          <.link
            navigate={~p"/app/settings/branding"}
            class="block bg-base-100 rounded-lg shadow p-6 hover:shadow-md transition-shadow"
          >
            <h2 class="text-lg font-semibold text-base-content">{gettext("Branding")}</h2>
            <p class="mt-2 text-sm text-base-content/70">
              {gettext("Customize career page appearance")}
            </p>
          </.link>

          <.link
            :if={@current_user.role == "admin"}
            navigate={~p"/app/settings/team"}
            class="block bg-base-100 rounded-lg shadow p-6 hover:shadow-md transition-shadow"
          >
            <h2 class="text-lg font-semibold text-base-content">{gettext("Team")}</h2>
            <p class="mt-2 text-sm text-base-content/70">
              {gettext("Manage team members and invites")}
            </p>
          </.link>

          <.link
            :if={@current_user.role == "admin"}
            navigate={~p"/app/settings/fields"}
            class="block bg-base-100 rounded-lg shadow p-6 hover:shadow-md transition-shadow"
          >
            <h2 class="text-lg font-semibold text-base-content">{gettext("Custom Fields")}</h2>
            <p class="mt-2 text-sm text-base-content/70">
              {gettext("Define custom fields for candidates and jobs")}
            </p>
          </.link>

          <.link
            :if={@current_user.role == "admin"}
            navigate={~p"/app/settings/scorecards"}
            class="block bg-base-100 rounded-lg shadow p-6 hover:shadow-md transition-shadow"
          >
            <h2 class="text-lg font-semibold text-base-content">{gettext("Scorecard Templates")}</h2>
            <p class="mt-2 text-sm text-base-content/70">
              {gettext("Define evaluation criteria for interviews")}
            </p>
          </.link>

          <.link
            :if={@current_user.role == "admin"}
            navigate={~p"/app/settings/emails"}
            class="block bg-base-100 rounded-lg shadow p-6 hover:shadow-md transition-shadow"
          >
            <h2 class="text-lg font-semibold text-base-content">{gettext("Message Templates")}</h2>
            <p class="mt-2 text-sm text-base-content/70">
              {gettext("Configure message templates for stage transitions")}
            </p>
          </.link>

          <.link
            :if={@current_user.role == "admin"}
            navigate={~p"/app/settings/notifications"}
            class="block bg-base-100 rounded-lg shadow p-6 hover:shadow-md transition-shadow"
          >
            <h2 class="text-lg font-semibold text-base-content">{gettext("Notifications")}</h2>
            <p class="mt-2 text-sm text-base-content/70">
              {gettext("Configure automated email notifications")}
            </p>
          </.link>

          <.link
            :if={@current_user.role == "admin"}
            navigate={~p"/app/settings/sources"}
            class="block bg-base-100 rounded-lg shadow p-6 hover:shadow-md transition-shadow"
          >
            <h2 class="text-lg font-semibold text-base-content">{gettext("Sources")}</h2>
            <p class="mt-2 text-sm text-base-content/70">
              {gettext("Manage how candidates find you")}
            </p>
          </.link>

          <.link
            navigate={~p"/app/settings/calendar"}
            class="block bg-base-100 rounded-lg shadow p-6 hover:shadow-md transition-shadow"
          >
            <h2 class="text-lg font-semibold text-base-content">{gettext("Calendar")}</h2>
            <p class="mt-2 text-sm text-base-content/70">
              {gettext("Connect Google Calendar for interview scheduling")}
            </p>
          </.link>

          <.link
            navigate={~p"/app/settings/availability"}
            class="block bg-base-100 rounded-lg shadow p-6 hover:shadow-md transition-shadow"
          >
            <h2 class="text-lg font-semibold text-base-content">{gettext("Availability")}</h2>
            <p class="mt-2 text-sm text-base-content/70">
              {gettext("Set your available hours for interviews")}
            </p>
          </.link>

          <.link
            navigate={~p"/app/settings/language"}
            class="block bg-base-100 rounded-lg shadow p-6 hover:shadow-md transition-shadow"
          >
            <h2 class="text-lg font-semibold text-base-content">{gettext("Language")}</h2>
            <p class="mt-2 text-sm text-base-content/70">{gettext("Set your preferred language")}</p>
          </.link>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
