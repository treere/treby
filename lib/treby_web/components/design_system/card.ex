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
        "card",
        @variant == "bordered" && "card-border",
        @variant == "elevated" && "card-lg",
        @variant == "flat" && "bg-transparent shadow-none",
        @class
      ]}
      {@rest}
    >
      <div :if={@header != []} class="card-header">
        {render_slot(@header)}
      </div>
      <div class={["card-body", @header == [] && "pt-6"]}>
        {render_slot(@inner_block)}
      </div>
      <div :if={@footer != []} class="card-footer border-t border-base-300 px-6 py-4">
        {render_slot(@footer)}
      </div>
    </div>
    """
  end
end
