defmodule TrebyWeb.DesignSystem.Pattern do
  use Phoenix.Component

  alias Phoenix.LiveView.JS

  import TrebyWeb.DesignSystem.Modal, only: [modal: 1]

  ## ── ConfirmDialog ──────────────────────────────────────────

  attr :id, :string, required: true
  attr :show, :boolean, default: false
  attr :title, :string, default: "Are you sure?"
  attr :message, :string, default: "This action cannot be undone."
  attr :confirm_label, :string, default: "Confirm"
  attr :cancel_label, :string, default: "Cancel"
  attr :confirm_variant, :string, values: ~w(primary danger), default: "danger"
  attr :on_confirm, :string, default: "confirm"
  attr :on_cancel, :string, default: nil, doc: "event sent on cancel — defaults to close-modal"
  attr :extra_attrs, :map, default: %{}, doc: "extra attrs sent with confirm event"
  attr :class, :any, default: nil
  attr :rest, :global

  @doc ~S'''
  Renders a confirmation dialog wrapping Modal.

  ## Examples

      <.confirm_dialog
        id="delete-user"
        show={@show_confirm}
        title="Delete user?"
        message="This permanently removes the user and all associated data."
        confirm_label="Delete"
        confirm_variant="danger"
        on_confirm="delete_user"
        extra_attrs={%{user_id: @user.id}}
      />

  Variants: `primary`, `danger` (default)
  '''
  def confirm_dialog(assigns) do
    assigns =
      assign(assigns, :extra_phx_value_attrs, phx_value_attrs(assigns.extra_attrs))

    ~H"""
    <.modal id={@id} show={@show} title={@title} close_event={@on_cancel} class={@class} {@rest}>
      <p class="text-sm text-zinc-600 dark:text-zinc-400 mb-6">{@message}</p>
      <:footer>
        <button
          type="button"
          phx-click={@on_cancel || "close-modal"}
          class="inline-flex items-center justify-center rounded-lg border border-zinc-200 dark:border-zinc-600 bg-white dark:bg-zinc-700 px-4 py-2 text-sm font-medium text-zinc-700 dark:text-zinc-200 hover:bg-zinc-50 dark:hover:bg-zinc-600 transition-colors"
        >
          {@cancel_label}
        </button>
        <button
          type="button"
          phx-click={@on_confirm}
          {@extra_phx_value_attrs}
          class={[
            "inline-flex items-center justify-center rounded-lg px-4 py-2 text-sm font-medium shadow-sm transition-colors focus:outline-none focus-visible:ring-2 focus-visible:ring-offset-2",
            @confirm_variant == "danger" &&
              "bg-red-600 text-white hover:bg-red-700 border border-red-600 focus-visible:ring-red-600",
            @confirm_variant == "primary" &&
              "bg-orange-600 text-white hover:bg-orange-700 border border-orange-600 focus-visible:ring-orange-600"
          ]}
          phx-mounted={JS.focus()}
        >
          {@confirm_label}
        </button>
      </:footer>
    </.modal>
    """
  end

  defp phx_value_attrs(extra_attrs) do
    Enum.map(extra_attrs, fn {key, value} ->
      {"phx-value-#{key}", value}
    end)
  end

  ## ── PageHeader ─────────────────────────────────────────────

  attr :title, :string, required: true
  attr :subtitle, :string, default: nil
  attr :breadcrumbs, :list, default: [], doc: "list of maps with `label` and optional `href`"
  attr :class, :any, default: nil
  attr :rest, :global

  slot :actions, doc: "action buttons or links rendered on the right"

  @doc ~S'''
  Renders a page header with title, breadcrumbs, subtitle, and actions.

  ## Examples

      <.page_header title="Users" subtitle="Manage user accounts">
        <:actions>
          <.button variant="primary" navigate={~p"/users/new"}>Add User</.button>
        </:actions>
      </.page_header>

  Breadcrumbs format: `[%{label: "Home", href: "/"}, %{label: "Users"}]`
  '''
  def page_header(assigns) do
    ~H"""
    <div class={["mb-6 pb-4 border-b border-zinc-100 dark:border-zinc-800", @class]} {@rest}>
      <nav
        :if={@breadcrumbs != []}
        class="flex items-center gap-2 text-sm text-zinc-500 dark:text-zinc-400 mb-2"
      >
        <.link
          :for={{crumb, idx} <- Enum.with_index(@breadcrumbs)}
          navigate={crumb[:href] || "#"}
          class={[
            "hover:text-zinc-700 dark:hover:text-zinc-200 transition-colors",
            idx == length(@breadcrumbs) - 1 && "text-zinc-900 dark:text-zinc-100 font-medium"
          ]}
        >
          {crumb.label}
          <.icon
            :if={idx < length(@breadcrumbs) - 1}
            name="hero-chevron-right"
            class="size-3 inline mx-1"
          />
        </.link>
      </nav>
      <div class="flex items-center justify-between gap-4">
        <div>
          <h1 class="text-2xl font-bold text-zinc-900 dark:text-zinc-100">{@title}</h1>
          <p :if={@subtitle} class="text-sm text-zinc-500 dark:text-zinc-400 mt-1">{@subtitle}</p>
        </div>
        <div :if={@actions != []} class="flex items-center gap-3 flex-shrink-0">
          {render_slot(@actions)}
        </div>
      </div>
    </div>
    """
  end

  ## ── EmptyState ─────────────────────────────────────────────

  attr :icon, :string, default: "hero-inbox"
  attr :title, :string, required: true
  attr :description, :string, default: nil
  attr :action, :map, default: nil, doc: "single CTA as map with `href` and `label`"
  attr :actions, :list, default: [], doc: "multiple CTAs as list of maps with `href` and `label`"
  attr :class, :any, default: nil
  attr :rest, :global

  slot :cta, doc: "custom slot for single CTA (overrides :action attr)"

  @doc ~S'''
  Renders an empty state with icon, title, description, and optional action.

  ## Examples

      <.empty_state
        title="No users yet"
        description="Invite team members to get started."
        action={%{href: ~p"/users/invite", label: "Invite Users"}}
      />

  Use the `:cta` slot for custom action content instead of the `action` attr.
  '''
  def empty_state(assigns) do
    actions = if assigns.action, do: [assigns.action | assigns.actions], else: assigns.actions
    assigns = assign(assigns, :computed_actions, actions)

    ~H"""
    <div class={["flex flex-col items-center justify-center py-16 px-6 text-center", @class]} {@rest}>
      <div class="rounded-full bg-zinc-100 dark:bg-zinc-800 p-4 mb-4">
        <.icon name={@icon} class="size-8 text-zinc-400 dark:text-zinc-500" />
      </div>
      <h3 class="text-lg font-semibold text-zinc-900 dark:text-zinc-100 mb-2">{@title}</h3>
      <p :if={@description} class="text-sm text-zinc-500 dark:text-zinc-400 max-w-sm mb-6">
        {@description}
      </p>
      <div :if={@cta != []}>
        {render_slot(@cta)}
      </div>
      <div
        :if={@computed_actions != [] && @cta == []}
        class="flex flex-wrap items-center justify-center gap-3"
      >
        <.link
          :for={act <- @computed_actions}
          navigate={act.href}
          class="inline-flex items-center justify-center rounded-lg bg-orange-600 px-4 py-2 text-sm font-medium text-white hover:bg-orange-700 shadow-sm transition-colors"
        >
          {act.label}
        </.link>
      </div>
    </div>
    """
  end

  ## ── FilterBar ──────────────────────────────────────────────

  attr :id, :string, required: true
  attr :fields, :list, default: [], doc: "list of filter field configs"
  attr :on_change, :string, default: "filter", doc: "event sent on filter change"
  attr :on_reset, :string, default: "reset_filters", doc: "event sent on reset"
  attr :class, :any, default: nil
  attr :rest, :global

  slot :inner_block, doc: "custom filter content rendered between fields and actions"

  @doc ~S'''
  Renders a filter bar with configurable fields and reset button.

  ## Examples

      <.filter_bar
        id="candidates-filter"
        fields={[
          %{key: "status", label: "Status", type: "text", value: @filter_status, placeholder: "Filter by status"},
          %{key: "search", label: "Search", type: "text", value: @filter_search, placeholder: "Search..."}
        ]}
        on_change="apply_filter"
        on_reset="reset_filters"
      />

  Each field accepts: `key`, `label`, `type`, `value`, `placeholder`, `debounce`
  '''
  def filter_bar(assigns) do
    ~H"""
    <div id={@id} class={["flex flex-wrap items-end gap-3 mb-4", @class]} {@rest}>
      <.filter_field :for={field <- @fields} field={field} on_change={@on_change} />
      {render_slot(@inner_block)}
      <button
        type="button"
        phx-click={@on_reset}
        class="inline-flex items-center justify-center rounded-lg border border-zinc-200 dark:border-zinc-600 bg-white dark:bg-zinc-700 px-3 py-1.5 text-sm font-medium text-zinc-700 dark:text-zinc-200 hover:bg-zinc-50 dark:hover:bg-zinc-600 transition-colors"
      >
        Reset
      </button>
    </div>
    """
  end

  attr :field, :map, required: true
  attr :on_change, :string, required: true

  defp filter_field(assigns) do
    ~H"""
    <div>
      <label
        :if={@field[:label]}
        class="label-text text-xs mb-1 block text-zinc-500 dark:text-zinc-400"
      >
        {@field[:label]}
      </label>
      <input
        type={@field[:type] || "text"}
        name={@field[:key]}
        value={@field[:value]}
        placeholder={@field[:placeholder] || ""}
        phx-change={@on_change}
        phx-debounce={@field[:debounce] || 300}
        class="h-9 rounded-lg border border-zinc-200 dark:border-zinc-600 bg-white dark:bg-zinc-800 px-3 text-sm text-zinc-900 dark:text-zinc-100 placeholder:text-zinc-400 focus:outline-none focus:ring-2 focus:ring-orange-500 focus:border-orange-500"
      />
    </div>
    """
  end

  ## ── FormSection ────────────────────────────────────────────

  attr :title, :string, required: true
  attr :description, :string, default: nil
  attr :id, :string, default: nil
  attr :class, :any, default: nil
  attr :rest, :global

  slot :inner_block

  @doc ~S'''
  Renders a form section grouping related fields.

  ## Examples

      <.form_section title="Contact Information" description="How to reach this candidate">
        <.input field={@form[:email]} type="email" label="Email" />
        <.input field={@form[:phone]} type="tel" label="Phone" />
      </.form_section>
  '''
  def form_section(assigns) do
    ~H"""
    <div id={@id} class={["mb-8", @class]} {@rest}>
      <div class="mb-4">
        <h3 class="text-base font-semibold text-zinc-900 dark:text-zinc-100">{@title}</h3>
        <p :if={@description} class="text-sm text-zinc-500 dark:text-zinc-400 mt-1">{@description}</p>
      </div>
      <div class="bg-white dark:bg-zinc-800 border border-zinc-200 dark:border-zinc-700 rounded-xl p-6 space-y-4 shadow-sm">
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end

  ## ── LoadingOverlay ─────────────────────────────────────────

  attr :loading, :boolean, default: false
  attr :label, :string, default: "Loading..."
  attr :class, :any, default: nil
  attr :rest, :global

  slot :inner_block

  @doc ~S'''
  Renders a dimmed overlay with spinner during loading.

  ## Examples

      <.loading_overlay loading={@syncing} label="Syncing data...">
        <div>Content that will be dimmed during loading</div>
      </.loading_overlay>
  '''
  def loading_overlay(assigns) do
    ~H"""
    <div class={["relative", @class]} {@rest}>
      <div
        :if={@loading}
        class="absolute inset-0 z-40 flex flex-col items-center justify-center bg-white/80 dark:bg-zinc-800/80 rounded-xl backdrop-blur-sm"
      >
        <.icon name="hero-arrow-path" class="size-8 text-orange-600 motion-safe:animate-spin mb-2" />
        <p class="text-sm text-zinc-500 dark:text-zinc-400">{@label}</p>
      </div>
      <div class={[@loading && "pointer-events-none opacity-40 transition-opacity duration-200"]}>
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end

  defp icon(assigns) do
    ~H"""
    <span class={[@name, @class]} />
    """
  end
end
