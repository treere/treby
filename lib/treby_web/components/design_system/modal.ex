defmodule TrebyWeb.DesignSystem.Modal do
  use Phoenix.Component

  alias Phoenix.LiveView.JS

  attr :id, :string, required: true
  attr :show, :boolean, default: false
  attr :title, :string, default: nil
  attr :size, :string, values: ~w(sm md lg xl), default: "md"
  attr :close_event, :string, default: nil, doc: "event sent on close (backdrop/escape)"
  attr :class, :any, default: nil
  attr :rest, :global

  slot :inner_block
  slot :footer

  @doc ~S'''
  Renders a modal dialog with backdrop and keyboard dismiss.

  ## Examples

      <.modal id="my-modal" show={@show_modal} title="Details">
        <p>Modal content</p>
        <:footer>
          <.button phx-click="close">Close</.button>
        </:footer>
      </.modal>

  Sizes: `sm`, `md` (default), `lg`, `xl`
  '''
  def modal(assigns) do
    ~H"""
    <div
      id={@id}
      class={[
        "fixed inset-0 z-50 flex items-center justify-center transition-all duration-200",
        unless(@show, do: "hidden")
      ]}
      phx-click={close_event(@close_event, @id)}
      phx-window-keydown={close_event(@close_event, @id)}
      phx-key="Escape"
      {@rest}
    >
      <div class="fixed inset-0 bg-black/50 transition-opacity duration-200" />
      <div
        class={[
          "relative bg-white dark:bg-zinc-800 rounded-xl shadow-xl border border-zinc-200 dark:border-zinc-700 max-h-[85vh] overflow-y-auto z-10 mx-4 w-full transition-all duration-200",
          size_class(@size),
          @class
        ]}
        phx-click-stop-propagation
      >
        <div
          :if={@title}
          class="flex items-center justify-between border-b border-zinc-100 dark:border-zinc-700 px-6 py-4"
        >
          <h3 class="text-lg font-semibold text-zinc-900 dark:text-zinc-100">{@title}</h3>
          <button
            type="button"
            phx-click={close_event(@close_event, @id)}
            class="text-zinc-400 hover:text-zinc-600 dark:text-zinc-500 dark:hover:text-zinc-300 transition-colors cursor-pointer"
            aria-label="Close"
          >
            <.icon name="hero-x-mark" class="size-5" />
          </button>
        </div>
        <div class="px-6 py-4">
          {render_slot(@inner_block)}
        </div>
        <div
          :if={@footer != []}
          class="flex items-center justify-end gap-3 border-t border-zinc-100 dark:border-zinc-700 px-6 py-4 bg-zinc-50/50 dark:bg-zinc-800/50 rounded-b-xl"
        >
          {render_slot(@footer)}
        </div>
      </div>
    </div>
    """
  end

  defp size_class("sm"), do: "max-w-sm"
  defp size_class("md"), do: "max-w-md"
  defp size_class("lg"), do: "max-w-lg"
  defp size_class("xl"), do: "max-w-xl"

  defp close_event(nil, id),
    do: JS.push("close-modal", value: %{id: id}) |> JS.add_class("hidden", to: "##{id}")

  defp close_event(event, id), do: JS.push(event) |> JS.add_class("hidden", to: "##{id}")

  defp icon(assigns) do
    ~H"""
    <span class={[@name, @class]} />
    """
  end
end
