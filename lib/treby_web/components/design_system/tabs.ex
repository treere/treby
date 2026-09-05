defmodule TrebyWeb.DesignSystem.Tabs do
  use Phoenix.Component

  alias Phoenix.LiveView.JS

  attr :id, :string, required: true

  attr :tabs, :list,
    required: true,
    doc: "list of maps with `key`, `label`, and optionally `count`"

  attr :active_tab, :any, default: nil, doc: "currently active tab key (controlled via assign)"
  attr :on_change, :string, default: "switch_tab", doc: "event sent when a tab is clicked"
  attr :class, :any, default: nil
  attr :rest, :global

  slot :inner_block, doc: "rendered below the tab bar"

  @doc ~S'''
  Renders tab navigation with optional count badges.

  ## Examples

      <.tabs id="page-tabs"
        tabs={[
          %{key: "active", label: "Active", count: 5},
          %{key: "archived", label: "Archived"}
        ]}
        active_tab={@active_tab}
        on_change="switch_tab"
      />

  Each tab accepts `key`, `label`, optional `count`, and optional `patch`.
  '''
  def tabs(assigns) do
    ~H"""
    <div id={@id} {@rest}>
      <div class={[
        "inline-flex items-center gap-1 p-1 bg-zinc-100 dark:bg-zinc-800 rounded-lg mb-4",
        @class
      ]}>
        <.link
          :for={tab <- @tabs}
          patch={tab[:patch]}
          phx-click={if(!tab[:patch], do: JS.push(@on_change, value: %{tab: tab.key}))}
          class={[
            "px-3 py-1.5 text-sm font-medium rounded-md transition-colors",
            @active_tab == tab.key &&
              "bg-white dark:bg-zinc-700 text-zinc-900 dark:text-zinc-100 shadow-sm border border-zinc-200 dark:border-zinc-600",
            @active_tab != tab.key &&
              "text-zinc-500 dark:text-zinc-400 hover:text-zinc-900 dark:hover:text-zinc-100"
          ]}
        >
          {tab.label}
          <span
            :if={tab[:count]}
            class="ml-1 inline-flex items-center justify-center rounded-full bg-zinc-200 dark:bg-zinc-600 text-zinc-700 dark:text-zinc-200 text-xs px-1.5 py-0.5"
          >{tab.count}</span>
        </.link>
      </div>
      {render_slot(@inner_block)}
    </div>
    """
  end
end
