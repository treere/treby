defmodule TrebyWeb.NotificationsLive do
  use TrebyWeb, :live_view

  alias Treby.Notifications.Inbox

  @page_size 20

  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  def mount(params, session, socket) do
    socket = set_locale_from_session(socket, session)

    {user, tenant} =
      cond do
        socket.assigns[:current_user] && socket.assigns[:current_tenant] ->
          {socket.assigns.current_user, socket.assigns.current_tenant}

        session["user_id"] && session["tenant_id"] ->
          {Treby.Accounts.get_user!(session["user_id"]),
           Treby.Tenants.get_tenant!(session["tenant_id"])}

        session["user_id"] ->
          u = Treby.Accounts.get_user!(session["user_id"])

          case Treby.Memberships.list_tenants_for_user(u.id) do
            [%{tenant: t} | _] -> {u, t}
            [] -> {u, nil}
          end

        true ->
          {nil, nil}
      end

    if connected?(socket) && user do
      Phoenix.PubSub.subscribe(Treby.PubSub, "notifications:#{user.id}")
    end

    filter = parse_filter(params["filter"])
    type = params["type"] || ""
    search = params["search"] || ""
    page = parse_page(params["page"])

    socket =
      socket
      |> assign(current_user: user, current_tenant: tenant)
      |> assign(filter: filter, type_filter: type, search: search, page: page)
      |> load_notifications()

    {:ok, socket}
  end

  def handle_params(params, _url, socket) do
    filter = parse_filter(params["filter"])
    type = params["type"] || ""
    search = params["search"] || ""
    page = parse_page(params["page"])

    {:noreply,
     socket
     |> assign(filter: filter, type_filter: type, search: search, page: page)
     |> load_notifications()}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app
      flash={@flash}
      current_scope={@current_user}
      current_tenant={@current_tenant}
      locale={@locale}
      available_tenants={assigns[:available_tenants] || []}
    >
      <div class="p-8 max-w-4xl mx-auto">
        <div class="flex items-center justify-between mb-6">
          <h1 class="text-2xl font-bold text-zinc-900 dark:text-zinc-100">
            {gettext("Notifications")}
          </h1>
          <button
            :if={@unread_count > 0}
            phx-click="mark_all_read"
            class="text-sm font-medium text-orange-600 hover:text-orange-700"
          >
            Mark all read
          </button>
        </div>

        <div class="flex flex-wrap gap-3 mb-6">
          <.link
            patch={
              notifications_path(@current_tenant, %{
                filter: "all",
                type: @type_filter,
                search: @search
              })
            }
            class={[
              "px-3 py-1.5 rounded-full text-sm font-medium border",
              @filter == :all &&
                "bg-zinc-900 text-white border-zinc-900 dark:bg-white dark:text-zinc-900",
              @filter != :all && "bg-white dark:bg-zinc-800 border-zinc-200 dark:border-zinc-700"
            ]}
          >
            All ({@counts.total})
          </.link>
          <.link
            patch={
              notifications_path(@current_tenant, %{
                filter: "unread",
                type: @type_filter,
                search: @search
              })
            }
            class={[
              "px-3 py-1.5 rounded-full text-sm font-medium border",
              @filter == :unread &&
                "bg-zinc-900 text-white border-zinc-900 dark:bg-white dark:text-zinc-900",
              @filter != :unread && "bg-white dark:bg-zinc-800 border-zinc-200 dark:border-zinc-700"
            ]}
          >
            Unread ({@counts.unread})
          </.link>
          <form id="notifications-search" phx-change="search" class="flex-1 min-w-[200px]">
            <input
              type="text"
              name="search"
              value={@search}
              placeholder={gettext("Search title or body...")}
              class="w-full rounded-lg border border-zinc-200 dark:border-zinc-700 bg-white dark:bg-zinc-800 px-3 py-2 text-sm"
            />
          </form>
          <form id="notifications-type-filter" phx-change="filter_type">
            <select
              name="type"
              class="rounded-lg border border-zinc-200 dark:border-zinc-700 bg-white dark:bg-zinc-800 px-3 py-2 text-sm"
            >
              <option value="" selected={@type_filter == ""}>{gettext("All types")}</option>
              <option value="new_application" selected={@type_filter == "new_application"}>
                New application
              </option>
              <option value="interview_scheduled" selected={@type_filter == "interview_scheduled"}>
                Interview scheduled
              </option>
              <option value="interview_cancelled" selected={@type_filter == "interview_cancelled"}>
                Interview cancelled
              </option>
              <option value="stage_change" selected={@type_filter == "stage_change"}>
                Stage change
              </option>
            </select>
          </form>
        </div>

        <div id="notifications" phx-update="stream" class="space-y-2">
          <div
            :for={{id, n} <- @streams.notifications}
            id={id}
            class={[
              "flex gap-3 p-4 rounded-xl border",
              is_nil(n.read_at) &&
                "bg-white dark:bg-zinc-800 border-zinc-200 dark:border-zinc-700 shadow-sm",
              !is_nil(n.read_at) &&
                "bg-zinc-50 dark:bg-zinc-800/50 border-zinc-100 dark:border-zinc-700 opacity-70"
            ]}
          >
            <span
              :if={is_nil(n.read_at)}
              class="mt-1 w-2 h-2 rounded-full bg-orange-500 flex-shrink-0"
            ></span>
            <span
              :if={!is_nil(n.read_at)}
              class="mt-1 w-2 h-2 rounded-full bg-zinc-300 dark:bg-zinc-600 flex-shrink-0"
            ></span>
            <div class="flex-1 min-w-0">
              <p class={[
                "text-sm truncate",
                is_nil(n.read_at) && "font-semibold text-zinc-900 dark:text-zinc-100",
                !is_nil(n.read_at) && "text-zinc-600 dark:text-zinc-400"
              ]}>
                {n.title}
              </p>
              <p :if={n.body} class="text-xs text-zinc-500 dark:text-zinc-400 truncate">{n.body}</p>
              <p class="text-[11px] text-zinc-400 mt-1">
                {Calendar.strftime(n.inserted_at, "%b %d %H:%M")} · {n.type}
              </p>
            </div>
            <div class="flex items-center gap-2 flex-shrink-0">
              <button
                :if={is_nil(n.read_at)}
                phx-click="mark_read"
                phx-value-id={n.id}
                class="text-xs font-medium text-orange-600 hover:text-orange-700"
              >{gettext("Mark read")}</button>
              <.link
                :if={n.link}
                navigate={n.link}
                phx-click="mark_read"
                phx-value-id={n.id}
                class="text-xs font-medium text-zinc-500 dark:text-zinc-400 hover:text-zinc-700"
              >{gettext("View")}</.link>
            </div>
          </div>
        </div>
        <div
          :if={@counts.total == 0}
          class="text-center py-12 text-sm text-zinc-500 dark:text-zinc-400"
        >
          No notifications yet
        </div>

        <div class="mt-6">
          <.pagination
            id="notifications-pagination"
            page={@page}
            total_pages={@total_pages}
            total_count={@counts.total}
            page_size={@page_size}
            patch={
              fn p ->
                notifications_path(@current_tenant, %{
                  filter: @filter,
                  type: @type_filter,
                  search: @search,
                  page: p
                })
              end
            }
          />
        </div>
      </div>
    </Layouts.app>
    """
  end

  def handle_event("mark_read", %{"id" => id}, socket) do
    {:ok, _} =
      Inbox.mark_read(id, socket.assigns.current_user.id, socket.assigns.current_tenant.id)

    {:noreply, load_notifications(socket)}
  end

  def handle_event("mark_all_read", _params, socket) do
    {:ok, _} =
      Inbox.mark_all_read(socket.assigns.current_user.id, socket.assigns.current_tenant.id)

    {:noreply, load_notifications(socket)}
  end

  def handle_event("search", %{"search" => search}, socket) do
    {:noreply,
     push_patch(socket,
       to:
         ~p"/app/notifications?#{%{filter: socket.assigns.filter, type: socket.assigns.type_filter, search: search}}"
     )}
  end

  def handle_event("filter_type", %{"type" => type}, socket) do
    {:noreply,
     push_patch(socket,
       to:
         ~p"/app/notifications?#{%{filter: socket.assigns.filter, type: type, search: socket.assigns.search}}"
     )}
  end

  def handle_info({:new_notification, notification}, socket) do
    # ensure stream insert respects current filter: just prepend
    {:noreply,
     socket
     |> stream_insert(:notifications, notification, at: 0)
     |> assign(
       counts: Inbox.counts(notification.recipient_id, notification.tenant_id),
       unread_count: Inbox.unread_count(notification.recipient_id, notification.tenant_id)
     )}
  end

  def handle_info(_msg, socket), do: {:noreply, socket}

  defp load_notifications(socket) do
    user = socket.assigns.current_user
    tenant = socket.assigns.current_tenant
    filter = socket.assigns.filter
    type = socket.assigns.type_filter
    search = socket.assigns.search
    page = socket.assigns.page

    counts = if user && tenant, do: Inbox.counts(user.id, tenant.id), else: %{total: 0, unread: 0}
    unread_count = counts.unread
    offset = (page - 1) * @page_size

    notifications =
      if user && tenant do
        Inbox.list_for_user(user.id, tenant.id,
          filter: filter,
          type: type,
          search: search,
          limit: @page_size,
          offset: offset
        )
      else
        []
      end

    total_pages = max(1, ceil_div(counts.total, @page_size))

    socket
    |> assign(
      counts: counts,
      unread_count: unread_count,
      page: page,
      total_pages: total_pages,
      page_size: @page_size
    )
    |> stream(:notifications, notifications, reset: true)
  end

  defp parse_filter("unread"), do: :unread
  defp parse_filter(_), do: :all

  defp parse_page(nil), do: 1

  defp parse_page(p) when is_binary(p) do
    case Integer.parse(p) do
      {n, _} when n > 0 -> n
      _ -> 1
    end
  end

  defp parse_page(n) when is_integer(n) and n > 0, do: n
  defp parse_page(_), do: 1

  defp ceil_div(a, b) when b > 0, do: div(a + b - 1, b)

  defp notifications_base_path(nil), do: "/app/notifications"

  defp notifications_base_path(%{slug: slug}) when is_binary(slug),
    do: "/#{slug}/app/notifications"

  defp notifications_base_path(_), do: "/app/notifications"

  defp notifications_path(tenant, params) do
    base = notifications_base_path(tenant)
    query = params |> Enum.reject(fn {_k, v} -> v == "" or is_nil(v) end) |> URI.encode_query()
    if query == "", do: base, else: base <> "?" <> query
  end
end
