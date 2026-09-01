defmodule TrebyWeb.DesignSystem.Button do
  use Phoenix.Component

  import TrebyWeb.DesignSystem, only: [variant_classes: 1, size_classes: 1]

  attr :variant, :string,
    values: ~w(primary secondary danger ghost outline),
    default: "primary"

  attr :size, :string, values: ~w(sm md lg), default: "md"

  attr :loading, :boolean, default: false, doc: "shows a spinner and disables the button"
  attr :disabled, :boolean, default: false
  attr :class, :any, default: nil

  attr :rest, :global,
    include: ~w(href navigate patch method download name value disabled form type target rel)

  slot :inner_block
  slot :icon, doc: "icon rendered before the label"

  @doc ~S'''
  Renders a button with variant, size, loading, and link support.

  ## Examples

      <.button>Save</.button>
      <.button variant="danger" size="lg">Delete</.button>
      <.button variant="outline" loading>Processing…</.button>
      <.button variant="secondary" navigate={~p"/users"}>All Users</.button>

  Variants: `primary` (default), `secondary`, `danger`, `ghost`, `outline`
  Sizes: `sm`, `md` (default), `lg`
  '''
  def button(assigns) do
    assigns = assign(assigns, :classes, button_classes(assigns))

    if assigns.rest[:href] || assigns.rest[:navigate] || assigns.rest[:patch] do
      ~H"""
      <.link class={@classes} {@rest}>
        <.icon :if={@loading} name="hero-arrow-path" class="size-4 motion-safe:animate-spin" />
        <span :if={@icon != []} class="flex-shrink-0">{render_slot(@icon)}</span>
        <span>{render_slot(@inner_block)}</span>
      </.link>
      """
    else
      ~H"""
      <button
        type={@rest[:type] || "button"}
        class={@classes}
        disabled={@loading or @disabled}
        {@rest}
      >
        <.icon :if={@loading} name="hero-arrow-path" class="size-4 motion-safe:animate-spin" />
        <span :if={@icon != []} class="flex-shrink-0">{render_slot(@icon)}</span>
        <span>{render_slot(@inner_block)}</span>
      </button>
      """
    end
  end

  defp button_classes(assigns) do
    [
      "btn inline-flex items-center justify-center gap-2 transition-all duration-150",
      variant_classes(assigns.variant),
      size_classes(assigns.size),
      (assigns.loading or assigns.disabled) && "pointer-events-none opacity-60",
      assigns.class
    ]
  end

  defp icon(assigns) do
    ~H"""
    <span class={[@name, @class]} />
    """
  end
end
