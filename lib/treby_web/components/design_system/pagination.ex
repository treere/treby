defmodule TrebyWeb.DesignSystem.Pagination do
  use Phoenix.Component

  attr :page, :integer, required: true, doc: "current page (1-based)"
  attr :total_pages, :integer, required: true
  attr :total_count, :integer, default: 0, doc: "total entries across pages"
  attr :page_size, :integer, default: 25
  attr :id, :string, default: "pagination"

  attr :patch, :any,
    default: nil,
    doc: "1-arity function mapping page -> path, rendered as <.link patch>"

  attr :event, :string,
    default: nil,
    doc: "phx-click event name (receives phx-value-page) when patch is nil"

  attr :class, :any, default: nil
  attr :rest, :global

  @doc ~S'''
  Renders a pager with Prev/Next buttons, windowed page numbers, and a
  "Showing X–Y of Z" result count. Hidden when there is a single page.

  ## Examples

      <.pagination page={@page.page} total_pages={@page.total_pages} total_count={@page.total_count} patch={&~p"/app/candidates?page=#{&1}"} />
      <.pagination page={1} total_pages={5} total_count={121} event="paginate" />
  '''
  def pagination(%{total_pages: total_pages} = assigns)
      when total_pages <= 1 do
    ~H"""
    <span class="hidden" id={@id} />
    """
  end

  def pagination(assigns) do
    assigns =
      assigns
      |> assign(:pages, page_window(assigns.page, assigns.total_pages))
      |> assign(:range_start, (assigns.page - 1) * assigns.page_size + 1)
      |> assign(
        :range_end,
        min(assigns.page * assigns.page_size, assigns.total_count)
      )

    ~H"""
    <nav
      id={@id}
      aria-label="Pagination"
      class={["flex items-center justify-between gap-4", @class]}
      {@rest}
    >
      <p class="text-sm text-zinc-500 dark:text-zinc-400">
        Showing {@range_start}–{@range_end} of {@total_count}
      </p>
      <div class="flex items-center gap-1">
        <%= if @patch do %>
          <.link
            patch={@patch.(max(@page - 1, 1))}
            aria-label="Previous page"
            class={[page_button_classes(), @page <= 1 && "pointer-events-none opacity-40"]}
            aria-disabled={@page <= 1}
          >
            <.icon name="hero-chevron-left" class="size-4" />
          </.link>
          <.link
            :for={p <- @pages}
            :if={is_integer(p)}
            patch={@patch.(p)}
            aria-label={"Page #{p}"}
            aria-current={p == @page && "page"}
            class={[page_button_classes(), p == @page && active_page_classes()]}
          >
            {p}
          </.link>
          <span :for={p <- @pages} :if={!is_integer(p)} class="px-1 text-zinc-400">…</span>
          <.link
            patch={@patch.(min(@page + 1, @total_pages))}
            aria-label="Next page"
            class={[page_button_classes(), @page >= @total_pages && "pointer-events-none opacity-40"]}
            aria-disabled={@page >= @total_pages}
          >
            <.icon name="hero-chevron-right" class="size-4" />
          </.link>
        <% else %>
          <button
            type="button"
            phx-click={@event}
            phx-value-page={max(@page - 1, 1)}
            aria-label="Previous page"
            disabled={@page <= 1}
            class={[page_button_classes(), @page <= 1 && "pointer-events-none opacity-40"]}
          >
            <.icon name="hero-chevron-left" class="size-4" />
          </button>
          <button
            :for={p <- @pages}
            :if={is_integer(p)}
            type="button"
            phx-click={@event}
            phx-value-page={p}
            aria-label={"Page #{p}"}
            aria-current={p == @page && "page"}
            class={[page_button_classes(), p == @page && active_page_classes()]}
          >
            {p}
          </button>
          <span :for={p <- @pages} :if={!is_integer(p)} class="px-1 text-zinc-400">…</span>
          <button
            type="button"
            phx-click={@event}
            phx-value-page={min(@page + 1, @total_pages)}
            aria-label="Next page"
            disabled={@page >= @total_pages}
            class={[page_button_classes(), @page >= @total_pages && "pointer-events-none opacity-40"]}
          >
            <.icon name="hero-chevron-right" class="size-4" />
          </button>
        <% end %>
      </div>
    </nav>
    """
  end

  defp icon(assigns) do
    ~H"""
    <span class={[@name, @class]} />
    """
  end

  defp page_button_classes do
    "inline-flex min-h-[36px] min-w-[36px] items-center justify-center rounded-lg px-2 text-sm font-medium text-zinc-600 dark:text-zinc-300 hover:bg-zinc-100 dark:hover:bg-zinc-800 focus:outline-none focus-visible:ring-2 focus-visible:ring-orange-500"
  end

  defp active_page_classes do
    "bg-orange-600 text-white hover:bg-orange-600 dark:bg-orange-600 dark:text-white"
  end

  defp page_window(page, total) do
    lower = max(2, page - 1)
    upper = min(total - 1, page + 1)

    inner = if lower <= upper, do: Enum.to_list(lower..upper//1), else: []

    ([1] ++ inner ++ [total])
    |> Enum.uniq()
    |> Enum.sort()
    |> insert_ellipses()
  end

  defp insert_ellipses(pages) do
    pages
    |> Enum.chunk_every(2, 1, :discard)
    |> Enum.flat_map(fn
      [a, b] when b - a > 1 -> [a, :ellipsis]
      [a, _b] -> [a]
    end)
    |> Kernel.++([List.last(pages)])
  end
end
