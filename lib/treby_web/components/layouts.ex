defmodule TrebyWeb.Layouts do
  @moduledoc """
  This module holds layouts and related functionality
  used by your application.
  """
  use TrebyWeb, :html

  # Embed all files in layouts/* within this module.
  # The default root.html.heex file contains the HTML
  # skeleton of your application, namely HTML headers
  # and other static content.
  embed_templates "layouts/*"

  @doc """
  Renders your app layout.

  This function is typically invoked from every template,
  and it often contains your application menu, sidebar,
  or similar.

  ## Examples

      <Layouts.app flash={@flash}>
        <h1>{gettext("Content")}</h1>
      </Layouts.app>

  """
  attr :flash, :map, required: true, doc: "the map of flash messages"

  attr :current_scope, :map,
    default: nil,
    doc: "the current [scope](https://hexdocs.pm/phoenix/scopes.html)"

  attr :locale, :string,
    default: "en",
    doc: "the current locale"

  attr :current_tenant, :map, default: nil
  attr :available_tenants, :list, default: []
  attr :current_membership, :map, default: nil

  slot :inner_block, required: true

  def app(assigns) do
    ~H"""
    <div class="min-h-screen bg-base-200">
      <nav class="bg-base-100 shadow">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div class="flex justify-between h-16">
            <div class="flex items-center">
              <.link
                navigate={if @current_tenant, do: "/#{@current_tenant.slug}/app", else: ~p"/app"}
                class="flex-shrink-0 flex items-center"
              >
                <span class="text-xl font-bold text-blue-600">Treby</span>
              </.link>
              <div
                :if={@available_tenants && length(@available_tenants) > 1}
                class="ml-4 relative"
                id="workspace-switcher"
              >
                <button
                  type="button"
                  class="flex items-center gap-1 text-sm font-medium text-base-content/80 hover:text-blue-600"
                  phx-click={Phoenix.LiveView.JS.toggle(to: "#workspace-switcher-dropdown")}
                >
                  <span>{(@current_tenant && @current_tenant.name) || gettext("Workspaces")}</span>
                  <.icon name="hero-chevron-down" class="w-4 h-4" />
                </button>
                <div
                  id="workspace-switcher-dropdown"
                  class="hidden absolute left-0 mt-2 w-64 bg-base-100 rounded-md shadow-lg py-1 z-50 border"
                >
                  <div :for={%{tenant: t, role: r} <- @available_tenants} class="px-2">
                    <.link
                      navigate={"/#{t.slug}/app"}
                      class={[
                        "flex justify-between items-center px-3 py-2 text-sm rounded hover:bg-base-200",
                        @current_tenant && @current_tenant.id == t.id && "bg-base-200 font-medium"
                      ]}
                    >
                      <span>{t.name}</span>
                      <span class="badge badge-xs">{r}</span>
                    </.link>
                  </div>
                  <div class="border-t mt-1 pt-1 px-2">
                    <.link
                      navigate={~p"/choose-tenant"}
                      class="block px-3 py-2 text-sm text-blue-600 hover:bg-base-200 rounded"
                    >
                      {gettext("Create new company")}
                    </.link>
                  </div>
                </div>
              </div>
              <div class="hidden sm:ml-6 sm:flex sm:space-x-8">
                <.link
                  navigate={
                    if @current_tenant, do: "/#{@current_tenant.slug}/app/jobs", else: ~p"/app/jobs"
                  }
                  data-nav="/app/jobs"
                  class="nav-link inline-flex items-center px-1 pt-1 text-sm font-medium text-base-content border-b-2 border-transparent hover:border-blue-500"
                >
                  {gettext("Jobs")}
                </.link>
                <.link
                  navigate={
                    if @current_tenant,
                      do: "/#{@current_tenant.slug}/app/candidates",
                      else: ~p"/app/candidates"
                  }
                  data-nav="/app/candidates"
                  class="nav-link inline-flex items-center px-1 pt-1 text-sm font-medium text-base-content border-b-2 border-transparent hover:border-blue-500"
                >
                  {gettext("Candidates")}
                </.link>
                <.link
                  navigate={
                    if @current_tenant,
                      do: "/#{@current_tenant.slug}/app/import",
                      else: ~p"/app/import"
                  }
                  data-nav="/app/import"
                  class="nav-link inline-flex items-center px-1 pt-1 text-sm font-medium text-base-content border-b-2 border-transparent hover:border-blue-500"
                >
                  {gettext("Import")}
                </.link>
                <.link
                  navigate={
                    if @current_tenant,
                      do: "/#{@current_tenant.slug}/app/interviews",
                      else: ~p"/app/interviews"
                  }
                  data-nav="/app/interviews"
                  class="nav-link inline-flex items-center px-1 pt-1 text-sm font-medium text-base-content border-b-2 border-transparent hover:border-blue-500"
                >
                  {gettext("Interviews")}
                </.link>
                <.link
                  navigate={
                    if @current_tenant,
                      do: "/#{@current_tenant.slug}/app/analytics",
                      else: ~p"/app/analytics"
                  }
                  data-nav="/app/analytics"
                  class="nav-link inline-flex items-center px-1 pt-1 text-sm font-medium text-base-content border-b-2 border-transparent hover:border-blue-500"
                >
                  {gettext("Analytics")}
                </.link>
                <.link
                  navigate={
                    if @current_tenant,
                      do: "/#{@current_tenant.slug}/app/messages-queue",
                      else: ~p"/app/messages-queue"
                  }
                  data-nav="/app/messages-queue"
                  class="nav-link inline-flex items-center px-1 pt-1 text-sm font-medium text-base-content border-b-2 border-transparent hover:border-blue-500"
                >
                  {gettext("Message Queue")}
                </.link>
                <.link
                  :if={
                    (@current_membership && @current_membership.role == "admin") ||
                      (@current_scope && Map.get(@current_scope, :role) == "admin")
                  }
                  navigate={
                    if @current_tenant,
                      do: "/#{@current_tenant.slug}/app/settings",
                      else: ~p"/app/settings"
                  }
                  data-nav="/app/settings"
                  class="nav-link inline-flex items-center px-1 pt-1 text-sm font-medium text-base-content border-b-2 border-transparent hover:border-blue-500"
                >
                  {gettext("Settings")}
                </.link>
              </div>
            </div>
            <div class="hidden sm:flex sm:items-center sm:space-x-4">
              <.theme_toggle />
              <.locale_switcher locale={@locale} />
              <span :if={@current_scope} class="text-sm text-base-content/70">
                {@current_scope.name}
              </span>
              <.link
                href={~p"/session"}
                method="delete"
                class="text-sm text-base-content/70 hover:text-base-content"
              >
                {gettext("Logout")}
              </.link>
            </div>
          </div>
        </div>
      </nav>

      <%!-- Mobile hamburger button --%>
      <button
        phx-click={
          Phoenix.LiveView.JS.toggle_class("hidden", to: "#mobile-nav-overlay")
          |> Phoenix.LiveView.JS.toggle_class("-translate-x-full", to: "#mobile-nav-drawer")
        }
        class="sm:hidden fixed top-4 left-4 z-50 p-2 bg-base-100 rounded-lg shadow-lg"
        aria-label={gettext("Toggle navigation")}
      >
        <.icon name="hero-bars-3" class="w-6 h-6 text-base-content/80" />
      </button>

      <%!-- Mobile navigation drawer --%>
      <div id="mobile-nav-overlay" class="sm:hidden fixed inset-0 bg-black/50 z-40 hidden" />
      <div
        id="mobile-nav-drawer"
        class="sm:hidden fixed inset-y-0 left-0 w-64 bg-base-100 shadow-xl z-50 transform -translate-x-full transition-transform"
      >
        <div class="p-4">
          <div class="flex justify-between items-center mb-6">
            <span class="text-xl font-bold text-blue-600">Treby</span>
            <button
              phx-click={
                Phoenix.LiveView.JS.toggle_class("hidden", to: "#mobile-nav-overlay")
                |> Phoenix.LiveView.JS.toggle_class("-translate-x-full", to: "#mobile-nav-drawer")
              }
              class="p-1"
            >
              <.icon name="hero-x-mark" class="w-6 h-6 text-base-content/50" />
            </button>
          </div>
          <div class="space-y-1">
            <.link
              navigate={
                if @current_tenant, do: "/#{@current_tenant.slug}/app/jobs", else: ~p"/app/jobs"
              }
              data-nav="/app/jobs"
              class="mobile-nav-link block px-3 py-2 rounded-lg text-base font-medium text-base-content hover:bg-base-200"
            >
              {gettext("Jobs")}
            </.link>
            <.link
              navigate={
                if @current_tenant,
                  do: "/#{@current_tenant.slug}/app/candidates",
                  else: ~p"/app/candidates"
              }
              data-nav="/app/candidates"
              class="mobile-nav-link block px-3 py-2 rounded-lg text-base font-medium text-base-content hover:bg-base-200"
            >
              {gettext("Candidates")}
            </.link>
            <.link
              navigate={
                if @current_tenant, do: "/#{@current_tenant.slug}/app/import", else: ~p"/app/import"
              }
              data-nav="/app/import"
              class="mobile-nav-link block px-3 py-2 rounded-lg text-base font-medium text-base-content hover:bg-base-200"
            >
              {gettext("Import")}
            </.link>
            <.link
              navigate={
                if @current_tenant,
                  do: "/#{@current_tenant.slug}/app/interviews",
                  else: ~p"/app/interviews"
              }
              data-nav="/app/interviews"
              class="mobile-nav-link block px-3 py-2 rounded-lg text-base font-medium text-base-content hover:bg-base-200"
            >
              {gettext("Interviews")}
            </.link>
            <.link
              navigate={
                if @current_tenant,
                  do: "/#{@current_tenant.slug}/app/analytics",
                  else: ~p"/app/analytics"
              }
              data-nav="/app/analytics"
              class="mobile-nav-link block px-3 py-2 rounded-lg text-base font-medium text-base-content hover:bg-base-200"
            >
              {gettext("Analytics")}
            </.link>
            <.link
              navigate={
                if @current_tenant,
                  do: "/#{@current_tenant.slug}/app/messages-queue",
                  else: ~p"/app/messages-queue"
              }
              data-nav="/app/messages-queue"
              class="mobile-nav-link block px-3 py-2 rounded-lg text-base font-medium text-base-content hover:bg-base-200"
            >
              {gettext("Message Queue")}
            </.link>
            <.link
              :if={
                (@current_membership && @current_membership.role == "admin") ||
                  (@current_scope && Map.get(@current_scope, :role) == "admin")
              }
              navigate={
                if @current_tenant,
                  do: "/#{@current_tenant.slug}/app/settings",
                  else: ~p"/app/settings"
              }
              data-nav="/app/settings"
              class="mobile-nav-link block px-3 py-2 rounded-lg text-base font-medium text-base-content hover:bg-base-200"
            >
              {gettext("Settings")}
            </.link>
          </div>
          <div class="border-t border-base-300 mt-4 pt-4 space-y-1">
            <div class="px-3 py-2 flex items-center justify-between">
              <div class="flex items-center gap-3">
                <.theme_toggle />
                <.locale_switcher locale={@locale} id_suffix="-mobile" />
              </div>
            </div>
            <.link
              href={~p"/session"}
              method="delete"
              class="block px-3 py-2 rounded-lg text-base font-medium text-base-content hover:bg-base-200"
            >
              {gettext("Logout")}
            </.link>
          </div>
        </div>
      </div>

      <main class="max-w-7xl mx-auto py-6 sm:px-6 lg:px-8">
        {render_slot(@inner_block)}
      </main>
    </div>

    <.flash_group flash={@flash} />
    """
  end

  @doc """
  Theme and locale toggles for unauthenticated pages (login, register, forgot
  password). Rendered in a fixed top-right corner so users can switch theme or
  language before signing in.
  """
  attr :locale, :string, required: true

  def auth_toolbar(assigns) do
    ~H"""
    <div class="absolute top-4 right-4 z-50 flex items-center gap-2">
      <.theme_toggle />
      <.locale_switcher locale={@locale} />
    </div>
    """
  end

  @doc """
  Layout for the candidate portal. Simplified navigation with tenant branding.
  """
  attr :flash, :map, required: true
  attr :current_candidate, :map, required: true
  attr :current_tenant, :map, required: true
  slot :inner_block, required: true

  def candidate_portal(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-50 dark:bg-gray-900">
      <nav class="bg-white dark:bg-gray-800 shadow">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div class="flex justify-between h-16">
            <div class="flex items-center">
              <.link
                navigate={"/#{@current_tenant.slug}/portal/messages"}
                class="flex-shrink-0 flex items-center"
              >
                <%= if @current_tenant.settings["logo_url"] do %>
                  <img src={@current_tenant.settings["logo_url"]} class="h-8 w-8" alt="" />
                <% else %>
                  <span class="text-xl font-bold text-blue-600">{@current_tenant.name}</span>
                <% end %>
              </.link>
            </div>
            <div class="flex items-center space-x-4">
              <.link
                navigate={"/#{@current_tenant.slug}/portal/messages"}
                class="text-sm font-medium text-gray-700 dark:text-gray-300 hover:text-blue-600"
              >
                Messages
              </.link>
              <.link
                navigate={"/#{@current_tenant.slug}/portal/schedule"}
                class="text-sm font-medium text-gray-700 dark:text-gray-300 hover:text-blue-600"
              >
                Schedule
              </.link>
              <.link
                navigate={"/#{@current_tenant.slug}/portal/settings"}
                class="text-sm font-medium text-gray-700 dark:text-gray-300 hover:text-blue-600"
              >
                Settings
              </.link>
              <span class="text-sm text-gray-500 dark:text-gray-400">
                {@current_candidate.name}
              </span>
              <.form
                for={%{}}
                action={~p"/#{@current_tenant.slug}/portal/logout"}
                method="post"
                class="inline"
              >
                <button
                  type="submit"
                  class="text-sm font-medium text-gray-700 dark:text-gray-300 hover:text-blue-600"
                >
                  Logout
                </button>
              </.form>
            </div>
          </div>
        </div>
      </nav>

      <.flash_group flash={@flash} />

      <main>
        {render_slot(@inner_block)}
      </main>
    </div>
    """
  end

  @doc """
  Locale switcher dropdown for changing language.
  """
  attr :locale, :string, required: true
  attr :id_suffix, :string, default: ""

  def locale_switcher(assigns) do
    assigns = assigns |> Map.update(:id_suffix, "", & &1)

    ~H"""
    <div class="relative" id={"locale-switcher#{@id_suffix}"}>
      <button
        type="button"
        class="flex items-center gap-x-1 text-sm font-medium text-base-content/80 hover:text-blue-600 transition-colors"
        phx-click={JS.toggle(to: "#locale-dropdown#{@id_suffix}")}
      >
        <.icon name="hero-language" class="h-4 w-4" />
        {String.upcase(@locale)}
      </button>
      <div
        id={"locale-dropdown#{@id_suffix}"}
        class="hidden absolute right-0 mt-2 w-32 bg-base-100 rounded-md shadow-lg py-1 z-50"
      >
        <.link
          href="/locale/en"
          class={[
            "block px-4 py-2 text-sm text-base-content/80 hover:bg-base-200",
            @locale == "en" && "font-bold text-blue-600"
          ]}
        >
          English
        </.link>
        <.link
          href="/locale/it"
          class={[
            "block px-4 py-2 text-sm text-base-content/80 hover:bg-base-200",
            @locale == "it" && "font-bold text-blue-600"
          ]}
        >
          Italiano
        </.link>
      </div>
    </div>
    """
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite">
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />

      <.flash
        id="client-error"
        kind={:error}
        title={gettext("We can't find the internet")}
        phx-disconnected={show(".phx-client-error #client-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={show(".phx-server-error #server-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#server-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>
    </div>
    """
  end

  @doc """
  Provides dark vs light theme toggle based on themes defined in app.css.

  See <head> in root.html.heex which applies the theme before page load.
  """
  def theme_toggle(assigns) do
    ~H"""
    <div class="card relative flex flex-row items-center border-2 border-base-300 bg-base-300 rounded-full">
      <div class="absolute w-1/3 h-full rounded-full border border-base-200 bg-base-100 brightness-200 left-0 [[data-theme=light]_&]:left-1/3 [[data-theme=dark]_&]:left-2/3 transition-[left]" />

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="system"
      >
        <.icon name="hero-computer-desktop-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="light"
      >
        <.icon name="hero-sun-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="dark"
      >
        <.icon name="hero-moon-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>
    </div>
    """
  end
end
