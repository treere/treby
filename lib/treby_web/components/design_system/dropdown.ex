defmodule TrebyWeb.DesignSystem.Dropdown do
  use Phoenix.Component

  attr :id, :string, required: true
  attr :align, :string, values: ~w(start end), default: "start"
  attr :class, :any, default: nil
  attr :rest, :global

  slot :trigger, required: true
  slot :item, required: true

  @doc ~S'''
  Renders a dropdown menu with trigger and items.

  ## Examples

      <.dropdown id="actions-dropdown" align="end">
        <:trigger>
          <.button variant="ghost">Actions</.button>
        </:trigger>
        <:item><.link navigate={~p"/edit"}>Edit</.link></:item>
        <:item><.link navigate={~p"/delete"}>Delete</.link></:item>
      </.dropdown>

  Alignment: `start` (default), `end`
  '''
  def dropdown(assigns) do
    ~H"""
    <div class={["dropdown", @align == "end" && "dropdown-end", @class]} {@rest}>
      <div tabindex="0" role="button" class="cursor-pointer">
        {render_slot(@trigger)}
      </div>
      <ul
        tabindex="0"
        class="dropdown-content menu bg-white dark:bg-zinc-800 rounded-xl z-30 w-52 p-2 shadow-xl border border-zinc-200 dark:border-zinc-700"
      >
        <li :for={item <- @item}>
          {render_slot(item)}
        </li>
      </ul>
    </div>
    """
  end
end
