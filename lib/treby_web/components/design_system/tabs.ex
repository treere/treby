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
      <div class={["tabs tabs-box mb-4", @class]}>
        <.link
          :for={tab <- @tabs}
          patch={tab[:patch]}
          phx-click={if(!tab[:patch], do: JS.push(@on_change, value: %{tab: tab.key}))}
          class={[
            "tab",
            @active_tab == tab.key && "tab-active"
          ]}
        >
          {tab.label}
          <span :if={tab[:count]} class="badge badge-sm ml-1">{tab.count}</span>
        </.link>
      </div>
      {render_slot(@inner_block)}
    </div>
    """
  end
end
