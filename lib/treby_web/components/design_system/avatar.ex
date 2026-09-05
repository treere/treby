defmodule TrebyWeb.DesignSystem.Avatar do
  use Phoenix.Component

  attr :src, :string, default: nil, doc: "image URL"
  attr :initials, :string, default: nil, doc: "fallback initials when no src"
  attr :alt, :string, default: ""
  attr :size, :string, values: ~w(xs sm md lg xl), default: "md"
  attr :class, :any, default: nil
  attr :rest, :global

  @doc ~S'''
  Renders a user avatar with image or initials fallback.

  ## Examples

      <.avatar src="/uploads/photo.jpg" alt="User" />
      <.avatar initials="JD" size="lg" />
      <.avatar initials="AB" size="sm" />

  Sizes: `xs`, `sm`, `md` (default), `lg`, `xl`
  '''
  def avatar(assigns) do
    ~H"""
    <div class={["avatar", @class]} {@rest}>
      <div class={[
        "rounded-full",
        @size == "xs" && "size-6",
        @size == "sm" && "size-8",
        @size == "md" && "size-10",
        @size == "lg" && "size-14",
        @size == "xl" && "size-20"
      ]}>
        <img :if={@src} src={@src} alt={@alt} class="object-cover w-full h-full" />
        <div
          :if={!@src && @initials}
          class="flex items-center justify-center w-full h-full bg-zinc-900 dark:bg-zinc-700 text-white dark:text-zinc-100 text-sm font-semibold"
        >
          {@initials}
        </div>
      </div>
    </div>
    """
  end
end
