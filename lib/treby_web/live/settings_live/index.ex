defmodule TrebyWeb.SettingsLive.Index do
  use TrebyWeb, :live_view

  alias Treby.{Accounts, Tenants}
  alias TrebyWeb.SettingsNav

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

    {:ok,
     assign(socket, settings_active: true) |> assign(current_user: user, current_tenant: tenant)}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app
      flash={@flash}
      current_scope={@current_user}
      locale={@locale}
      current_tenant={assigns[:current_tenant]}
      notification_unread_count={assigns[:notification_unread_count] || 0}
      notification_recent={assigns[:notification_recent] || []}
    >
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

        <div
          :if={@current_membership && @current_membership.role != "admin"}
          class="mt-4 rounded-xl border border-amber-200 dark:border-amber-800 bg-amber-50 dark:bg-amber-950 px-4 py-3 text-sm text-amber-800 dark:text-amber-200"
        >
          {gettext("Some settings require admin access. You see only your personal settings below.")}
        </div>

        <div class="mt-6">
          <TrebyWeb.SettingsLayout.settings_shell
            current_tenant={@current_tenant}
            current_membership={@current_membership}
            active_key={nil}
          >
            <div class="space-y-8">
              <div class="rounded-xl border border-zinc-200 dark:border-zinc-700 bg-white dark:bg-zinc-800 p-6">
                <h2 class="text-lg font-semibold text-zinc-900 dark:text-zinc-100">
                  {gettext("Select a setting")}
                </h2>
                <p class="mt-1 text-sm text-zinc-500 dark:text-zinc-400">
                  {gettext(
                    "Choose a section from the sidebar to configure your workspace. All changes are tenant-scoped."
                  )}
                </p>
              </div>

              <div
                :for={
                  group <-
                    SettingsNav.groups_for_role(
                      (@current_membership && @current_membership.role) || "member"
                    )
                }
                class="rounded-xl border border-zinc-200 dark:border-zinc-700 bg-white dark:bg-zinc-800 p-6"
              >
                <div class="flex items-center gap-2">
                  <.icon name={group.icon} class="w-5 h-5 text-zinc-500 dark:text-zinc-400" />
                  <h3 class="text-sm font-semibold text-zinc-900 dark:text-zinc-100 uppercase tracking-wider">
                    {group.label}
                  </h3>
                </div>
                <div class="mt-4 grid grid-cols-1 gap-3">
                  <.link
                    :for={item <- group.items}
                    id={"hub-#{item.dom_id}"}
                    navigate={SettingsNav.path_with_tenant(item.path, @current_tenant)}
                    class="flex items-start gap-3 rounded-lg border border-zinc-100 dark:border-zinc-700 px-4 py-3 hover:bg-zinc-50 dark:hover:bg-zinc-700/50 transition-colors"
                  >
                    <.icon name={item.icon} class="w-5 h-5 mt-0.5 text-zinc-400" />
                    <span class="flex-1">
                      <span class="block text-sm font-medium text-zinc-900 dark:text-zinc-100">{item.label}</span>
                      <span class="block text-xs text-zinc-500 dark:text-zinc-400">{item.subtitle}</span>
                    </span>
                  </.link>
                </div>
              </div>
            </div>
          </TrebyWeb.SettingsLayout.settings_shell>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
