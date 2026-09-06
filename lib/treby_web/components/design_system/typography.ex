defmodule TrebyWeb.DesignSystem.Typography do
  use Phoenix.Component

  @doc """
  Heading with consistent typography and dark-mode contrast.

  Levels:
  - :h1 -> text-2xl font-bold text-zinc-900 dark:text-zinc-100
  - :h2 -> text-xl font-bold text-zinc-900 dark:text-zinc-100
  - :h3 -> text-lg font-semibold text-zinc-900 dark:text-zinc-100
  - :h4 -> text-base font-semibold text-zinc-900 dark:text-zinc-100

  All levels include dark variants so titles remain readable on dark surfaces.
  Use class assign to adjust spacing (e.g., `mb-4`, `mt-2`).
  """
  attr :level, :atom, values: [:h1, :h2, :h3, :h4], default: :h2
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def heading(assigns) do
    ~H"""
    <div class={[heading_classes(@level), @class]} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  defp heading_classes(:h1), do: "text-2xl font-bold text-zinc-900 dark:text-zinc-100"
  defp heading_classes(:h2), do: "text-xl font-bold text-zinc-900 dark:text-zinc-100"
  defp heading_classes(:h3), do: "text-lg font-semibold text-zinc-900 dark:text-zinc-100"
  defp heading_classes(:h4), do: "text-base font-semibold text-zinc-900 dark:text-zinc-100"

  @doc """
  Subtitle / description text with muted zinc palette and dark variant.
  """
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def subtitle(assigns) do
    ~H"""
    <p class={["text-sm text-zinc-500 dark:text-zinc-400", @class]} {@rest}>
      {render_slot(@inner_block)}
    </p>
    """
  end

  @doc """
  Small muted text for captions, helper text.
  """
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def caption(assigns) do
    ~H"""
    <p class={["text-xs text-zinc-500 dark:text-zinc-400", @class]} {@rest}>
      {render_slot(@inner_block)}
    </p>
    """
  end

  @doc """
  Body text with proper dark contrast.
  """
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def body(assigns) do
    ~H"""
    <p class={["text-sm text-zinc-900 dark:text-zinc-100", @class]} {@rest}>
      {render_slot(@inner_block)}
    </p>
    """
  end
end
