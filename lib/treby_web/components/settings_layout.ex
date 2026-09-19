defmodule TrebyWeb.SettingsLayout do
  use TrebyWeb, :html

  alias TrebyWeb.SettingsNav

  attr :current_tenant, :map, default: nil
  attr :current_membership, :map, default: nil
  attr :active_key, :atom, default: nil
  attr :locale, :string, default: "en"

  slot :inner_block, required: true

  def settings_shell(assigns) do
    role = (assigns.current_membership && Map.get(assigns.current_membership, :role)) || "member"
    groups = SettingsNav.groups_for_role(role)
    assigns = assigns |> assign(:nav_groups, groups) |> assign(:nav_role, role)

    ~H"""
    <div
      class="flex flex-col lg:flex-row gap-6"
      id="settings-shell"
      phx-hook=".SettingsScroll"
      data-active={if @active_key, do: "1", else: "0"}
    >
      <!-- Sidebar -->
      <aside class="w-full lg:w-72 lg:shrink-0">
        <div class="bg-white dark:bg-zinc-800 rounded-xl border border-zinc-200 dark:border-zinc-700 shadow-sm lg:sticky lg:top-20">
          <nav class="p-4 space-y-6" aria-label="Settings">
            <div :for={group <- @nav_groups}>
              <div class="flex items-center gap-2 px-2 py-1">
                <.icon name={group.icon} class="w-4 h-4 text-zinc-400 dark:text-zinc-500" />
                <span class="text-xs font-semibold tracking-wider uppercase text-zinc-500 dark:text-zinc-400">
                  {group.label}
                </span>
              </div>
              <ul class="mt-2 space-y-1">
                <li :for={item <- group.items}>
                  <.link
                    id={item.dom_id}
                    navigate={SettingsNav.path_with_tenant(item.path, @current_tenant)}
                    aria-current={if @active_key == item.key, do: "page", else: nil}
                    class={[
                      "flex items-start gap-3 rounded-lg px-3 py-2.5 text-sm transition-colors",
                      if @active_key == item.key do
                        "bg-zinc-100 dark:bg-zinc-700 text-zinc-900 dark:text-zinc-100 font-medium"
                      else
                        "text-zinc-600 dark:text-zinc-400 hover:bg-zinc-50 dark:hover:bg-zinc-700/50 hover:text-zinc-900 dark:hover:text-zinc-100"
                      end
                    ]}
                  >
                    <.icon name={item.icon} class="w-5 h-5 mt-0.5 shrink-0 opacity-70" />
                    <span class="flex-1 min-w-0">
                      <span class="block leading-none">{item.label}</span>
                      <span class="block text-xs font-normal text-zinc-500 dark:text-zinc-400 mt-1 leading-tight">
                        {item.subtitle}
                      </span>
                    </span>
                    <span
                      :if={item.role == :admin}
                      class="shrink-0 inline-flex items-center rounded-full bg-zinc-100 dark:bg-zinc-700 border border-zinc-200 dark:border-zinc-600 px-1.5 py-0.5 text-[10px] font-medium text-zinc-600 dark:text-zinc-300"
                    >
                      Admin
                    </span>
                  </.link>
                </li>
                <!-- Cross-link for Company Availability under Scheduling -->
                <li :if={
                  group.id == :scheduling and @active_key != :company_availability and
                    @nav_role in ["admin", :admin]
                }>
                  <.link
                    navigate={
                      SettingsNav.path_with_tenant("/settings/company-availability", @current_tenant)
                    }
                    class="flex items-center gap-2 rounded-lg px-3 py-2 text-xs text-zinc-500 dark:text-zinc-400 hover:text-zinc-900 dark:hover:text-zinc-100 hover:bg-zinc-50 dark:hover:bg-zinc-700/50"
                    id="settings-nav-company-availability-crosslink"
                  >
                    <.icon name="hero-arrow-right" class="w-3.5 h-3.5" /> Manage company defaults →
                  </.link>
                </li>
              </ul>
            </div>
          </nav>
        </div>
      </aside>
      <!-- Main pane -->
      <div id="settings-main" class="flex-1 min-w-0">
        {render_slot(@inner_block)}
      </div>
    </div>

    <script :type={Phoenix.LiveView.ColocatedHook} name=".SettingsScroll">
      export default {
        mounted() {
          this.maybeScroll();
        },
        updated() {
          this.maybeScroll();
        },
        maybeScroll() {
          if (this.el.dataset.active !== "1") return;
          const target = document.getElementById("settings-main");
          if (target) target.scrollIntoView({ behavior: "smooth", block: "start" });
        }
      }
    </script>
    """
  end
end
