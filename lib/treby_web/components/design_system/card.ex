defmodule TrebyWeb.DesignSystem.Card do
  use Phoenix.Component

  attr :variant, :string, values: ~w(default bordered elevated flat), default: "default"
  attr :class, :any, default: nil
  attr :rest, :global

  slot :header
  slot :inner_block
  slot :footer

  @doc ~S'''
  Renders a card with header, body, and footer slots.

  ## Examples

      <.card>Simple content</.card>
      <.card variant="elevated">
        <:header>Title</:header>
        Body content
        <:footer>Actions</:footer>
      </.card>

  Variants: `default`, `bordered`, `elevated`, `flat`
  '''
  def card(assigns) do
    ~H"""
    <div
      class={[
        "bg-white dark:bg-zinc-800 rounded-xl border border-zinc-200 dark:border-zinc-700 shadow-sm",
        @variant == "bordered" && "border-zinc-300 dark:border-zinc-600",
        @variant == "elevated" && "shadow-md",
        @variant == "flat" &&
          "bg-transparent dark:bg-transparent shadow-none border-transparent dark:border-transparent",
        @class
      ]}
      {@rest}
    >
      <div :if={@header != []} class="px-6 py-4 border-b border-zinc-100 dark:border-zinc-700">
        {render_slot(@header)}
      </div>
      <div class={["px-6 py-4", @header == [] && "pt-6"]}>
        {render_slot(@inner_block)}
      </div>
      <div
        :if={@footer != []}
        class="px-6 py-4 border-t border-zinc-100 dark:border-zinc-700 bg-zinc-50/50 dark:bg-zinc-800/50 rounded-b-xl"
      >
        {render_slot(@footer)}
      </div>
    </div>
    """
  end
end
