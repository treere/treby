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
      <span :if={render_slot(@inner_block) != []} class="text-sm text-zinc-500 dark:text-zinc-400">
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
        class={["h-4 bg-zinc-200 dark:bg-zinc-700 rounded animate-pulse", @width || "w-full"]}
      />
      <div :if={@variant == "avatar"} class="flex items-center gap-3">
        <div class="size-10 bg-zinc-200 dark:bg-zinc-700 rounded-full animate-pulse" />
        <div class="space-y-2 flex-1">
          <div class="h-3 bg-zinc-200 dark:bg-zinc-700 rounded w-1/3 animate-pulse" />
          <div class="h-3 bg-zinc-200 dark:bg-zinc-700 rounded w-1/2 animate-pulse" />
        </div>
      </div>
      <div
        :if={@variant == "card"}
        class="space-y-3 p-4 border border-zinc-200 dark:border-zinc-700 rounded-xl bg-white dark:bg-zinc-800"
      >
        <div
          :for={_ <- Enum.to_list(1..@lines)}
          class="h-3 bg-zinc-200 dark:bg-zinc-700 rounded animate-pulse w-full"
        />
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
        "flex items-start gap-3 rounded-xl border shadow-lg p-4",
        @kind == :info &&
          "bg-blue-50 dark:bg-blue-950 border-blue-200 dark:border-blue-800 text-blue-800 dark:text-blue-100",
        @kind == :success &&
          "bg-emerald-50 dark:bg-emerald-950 border-emerald-200 dark:border-emerald-800 text-emerald-800 dark:text-emerald-100",
        @kind == :warning &&
          "bg-amber-50 dark:bg-amber-950 border-amber-200 dark:border-amber-800 text-amber-800 dark:text-amber-100",
        @kind == :error &&
          "bg-red-50 dark:bg-red-950 border-red-200 dark:border-red-800 text-red-800 dark:text-red-100",
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
