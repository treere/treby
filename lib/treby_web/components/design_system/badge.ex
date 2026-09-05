defmodule TrebyWeb.DesignSystem.Badge do
  use Phoenix.Component

  import TrebyWeb.DesignSystem, only: [badge_classes: 1]

  attr :variant, :string,
    values: ~w(default success warning danger info),
    default: "default"

  attr :dot, :boolean, default: false, doc: "shows a colored dot indicator"
  attr :class, :any, default: nil
  attr :rest, :global

  slot :inner_block

  @doc ~S'''
  Renders a badge with color variant and optional dot indicator.

  ## Examples

      <.badge>Active</.badge>
      <.badge variant="success" dot>Verified</.badge>
      <.badge variant="danger">Expired</.badge>

  Variants: `default`, `success`, `warning`, `danger`, `info`
  '''
  def badge(assigns) do
    ~H"""
    <span class={[badge_classes(@variant), "px-2.5 py-0.5", @class]} {@rest}>
      <span
        :if={@dot}
        class={[
          "inline-block size-1.5 rounded-full mr-1",
          @variant == "default" && "bg-zinc-500",
          @variant == "success" && "bg-emerald-600",
          @variant == "warning" && "bg-amber-500",
          @variant == "danger" && "bg-red-600",
          @variant == "info" && "bg-blue-600"
        ]}
      />
      {render_slot(@inner_block)}
    </span>
    """
  end
end
