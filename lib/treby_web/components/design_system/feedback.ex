defmodule TrebyWeb.DesignSystem.Feedback do
  use Phoenix.Component

  attr :size, :string, values: ~w(sm md lg), default: "md"
  attr :class, :any, default: nil
  attr :rest, :global

  slot :inner_block, doc: "optional label shown next to the spinner"

  @doc ~S'''
  Renders an animated loading spinner.

  ## Examples

      <.spinner />
      <.spinner size="lg">Loading candidates...</.spinner>
      <.spinner size="sm" />

  Sizes: `sm`, `md` (default), `lg`
  '''
  def spinner(assigns) do
    ~H"""
    <span class={["inline-flex items-center gap-2", @class]} {@rest}>
      <span class={[
        "inline-block animate-spin rounded-full border-2 border-current border-t-transparent",
        @size == "sm" && "size-4",
        @size == "md" && "size-5",
        @size == "lg" && "size-8"
      ]} />
      <span :if={render_slot(@inner_block) != []} class="text-sm text-base-content/70">
        {render_slot(@inner_block)}
      </span>
    </span>
    """
  end

  attr :variant, :string, values: ~w(text card avatar), default: "text"
  attr :width, :string, default: nil, doc: "Tailwind width class for text skeleton"
  attr :lines, :integer, default: 1, doc: "number of lines for card variant"
  attr :class, :any, default: nil
  attr :rest, :global

  @doc ~S'''
  Renders a placeholder skeleton for loading states.

  ## Examples

      <.skeleton variant="text" width="w-1/2" />
      <.skeleton variant="avatar" />
      <.skeleton variant="card" lines={3} />

  Variants: `text`, `avatar`, `card`
  '''
  def skeleton(assigns) do
    ~H"""
    <div class={[@class]} {@rest}>
      <div
        :if={@variant == "text"}
        class={["h-4 bg-base-300 rounded animate-pulse", @width || "w-full"]}
      />
      <div :if={@variant == "avatar"} class="flex items-center gap-3">
        <div class="size-10 bg-base-300 rounded-full animate-pulse" />
        <div class="space-y-2 flex-1">
          <div class="h-3 bg-base-300 rounded w-1/3 animate-pulse" />
          <div class="h-3 bg-base-300 rounded w-1/2 animate-pulse" />
        </div>
      </div>
      <div :if={@variant == "card"} class="space-y-3 p-4 border border-base-300 rounded-box">
        <div :for={_ <- Enum.to_list(1..@lines)} class="h-3 bg-base-300 rounded animate-pulse w-full" />
      </div>
    </div>
    """
  end

  attr :kind, :atom, values: [:info, :success, :warning, :error], default: :info
  attr :title, :string, default: nil
  attr :dismissable, :boolean, default: true
  attr :class, :any, default: nil
  attr :rest, :global

  slot :inner_block

  @doc ~S'''
  Renders a toast/alert notification.

  ## Examples

      <.toast kind={:info} title="Updated">Job saved successfully</.toast>
      <.toast kind={:error}>Something went wrong</.toast>

  Kinds: `info`, `success`, `warning`, `error`
  '''
  def toast(assigns) do
    ~H"""
    <div
      class={[
        "alert flex items-start gap-3 shadow-lg",
        @kind == :info && "alert-info",
        @kind == :success && "alert-success",
        @kind == :warning && "alert-warning",
        @kind == :error && "alert-error",
        @class
      ]}
      {@rest}
    >
      <div class="flex-1">
        <p :if={@title} class="font-semibold">{@title}</p>
        <p>{render_slot(@inner_block)}</p>
      </div>
    </div>
    """
  end
end
