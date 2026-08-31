defmodule TrebyWeb.SettingsLive.AuditLog do
  use TrebyWeb, :live_view

  alias Treby.{Accounts, Tenants, Audit}

  def mount(_params, session, socket) do
    socket = set_locale_from_session(socket, session)

    {user, tenant} =
      cond do
        socket.assigns[:current_user] && socket.assigns[:current_tenant] ->
          {socket.assigns.current_user, socket.assigns.current_tenant}

        session["user_id"] && session["tenant_id"] ->
          {Accounts.get_user!(session["user_id"]), Tenants.get_tenant!(session["tenant_id"])}

        session["user_id"] ->
          u = Accounts.get_user!(session["user_id"])

          case Treby.Memberships.list_tenants_for_user(u.id) do
            [%{tenant: t} | _] -> {u, t}
            [] -> {u, nil}
          end

        true ->
          {nil, nil}
      end

    socket =
      socket
      |> assign(current_user: user, current_tenant: tenant)
      |> assign(
        filters: %{
          "action" => "",
          "entity_type" => "",
          "search" => "",
          "actor_id" => "",
          "from" => "",
          "to" => ""
        }
      )
      |> assign(page: 1, page_size: 25, selected: nil, total: 0)
      |> assign(events: [])
      |> load_events()

    {:ok, stream(socket, :events, socket.assigns.events)}
  end

  def handle_params(params, _url, socket) do
    filters = build_filters(params, socket.assigns.filters)
    page = String.to_integer(params["page"] || to_string(socket.assigns.page))

    socket =
      socket
      |> assign(filters: filters, page: page)
      |> load_events()

    {:noreply, stream(socket, :events, socket.assigns.events, reset: true)}
  end

  defp build_filters(params, existing) do
    Enum.reduce(~w(action entity_type search actor_id from to), %{}, fn key, acc ->
      Map.put(acc, key, params[key] || existing[key] || "")
    end)
  end

  defp load_events(socket) do
    tenant = socket.assigns.current_tenant

    if is_nil(tenant) do
      assign(socket, events: [], total: 0)
    else
      opts = [
        action: socket.assigns.filters["action"],
        entity_type: socket.assigns.filters["entity_type"],
        search: socket.assigns.filters["search"],
        actor_id: socket.assigns.filters["actor_id"],
        from: parse_date(socket.assigns.filters["from"]),
        to: parse_date(socket.assigns.filters["to"]),
        page: socket.assigns.page,
        page_size: socket.assigns.page_size
      ]

      {events, _meta} = Audit.list_events(tenant.id, opts)
      total = Audit.count_events(tenant.id, opts)
      assign(socket, events: events, total: total)
    end
  end

  defp parse_date(nil), do: nil
  defp parse_date(""), do: nil

  defp parse_date(str) do
    case Date.from_iso8601(str) do
      {:ok, date} -> DateTime.new!(date, ~T[00:00:00], "Etc/UTC")
      _ -> nil
    end
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_user} locale={@locale}>
      <div class="p-8">
        <div class="mb-8">
          <.link navigate={~p"/app/settings"} class="text-blue-600 hover:text-blue-900 text-sm">
            &larr; {gettext("Back to Settings")}
          </.link>
          <h1 class="text-2xl font-bold mt-2">{gettext("Audit Log")}</h1>
          <p class="mt-1 text-base-content/70">
            {gettext("Immutable history of all changes in this workspace")}
          </p>
        </div>

        <div class="bg-base-100 rounded-lg shadow p-4 mb-6">
          <.form
            for={%{}}
            id="audit-filter-form"
            phx-change="filter"
            phx-submit="filter"
            class="grid grid-cols-1 md:grid-cols-3 gap-4"
          >
            <.input
              name="action"
              value={@filters["action"]}
              type="text"
              label={gettext("Action prefix")}
              placeholder="job. / candidate. / pipeline."
              id="filter-action"
            />
            <.input
              name="entity_type"
              value={@filters["entity_type"]}
              type="text"
              label={gettext("Entity type")}
              placeholder="job, candidate, application"
              id="filter-entity-type"
            />
            <.input
              name="search"
              value={@filters["search"]}
              type="text"
              label={gettext("Search")}
              placeholder={gettext("Search action or entity")}
              id="filter-search"
            />
            <.input
              name="actor_id"
              value={@filters["actor_id"]}
              type="text"
              label={gettext("Actor ID")}
              placeholder="user id"
              id="filter-actor"
            />
            <.input
              name="from"
              value={@filters["from"]}
              type="date"
              label={gettext("From date")}
              id="filter-from"
            />
            <.input
              name="to"
              value={@filters["to"]}
              type="date"
              label={gettext("To date")}
              id="filter-to"
            />
          </.form>
          <div class="mt-4 flex gap-2">
            <.button phx-click="clear_filters" variant="ghost">{gettext("Clear filters")}</.button>
          </div>
        </div>

        <div class="bg-base-100 rounded-lg shadow overflow-hidden">
          <div class="overflow-x-auto">
            <table class="min-w-full divide-y divide-base-200" id="audit-table">
              <thead class="bg-base-200">
                <tr>
                  <th class="px-4 py-3 text-left text-xs font-medium text-base-content/70 uppercase">
                    {gettext("Time")}
                  </th>
                  <th class="px-4 py-3 text-left text-xs font-medium text-base-content/70 uppercase">
                    {gettext("Action")}
                  </th>
                  <th class="px-4 py-3 text-left text-xs font-medium text-base-content/70 uppercase">
                    {gettext("Entity")}
                  </th>
                  <th class="px-4 py-3 text-left text-xs font-medium text-base-content/70 uppercase">
                    {gettext("Actor")}
                  </th>
                  <th class="px-4 py-3"></th>
                </tr>
              </thead>
              <tbody class="divide-y divide-base-200" id="audit-events" phx-update="stream">
                <tr :for={{dom_id, event} <- @streams.events} id={dom_id} class="hover:bg-base-50">
                  <td class="px-4 py-3 text-sm text-base-content/70">
                    {Calendar.strftime(event.inserted_at, "%Y-%m-%d %H:%M:%S UTC")}
                  </td>
                  <td class="px-4 py-3"><span class="badge badge-sm">{event.action}</span></td>
                  <td class="px-4 py-3 text-sm">
                    {event.entity_type}: {String.slice(event.entity_id, 0, 8)}
                  </td>
                  <td class="px-4 py-3 text-sm">
                    {(event.actor && event.actor.email) || event.actor_type}
                  </td>
                  <td class="px-4 py-3 text-right">
                    <button
                      phx-click="show_detail"
                      phx-value-id={event.id}
                      class="text-blue-600 hover:text-blue-900 text-sm"
                    >
                      {gettext("View")}
                    </button>
                  </td>
                </tr>
              </tbody>
            </table>
            <div :if={@events == []} class="text-center py-8 text-base-content/50">
              {gettext("No audit events found")}
            </div>
          </div>

          <div class="p-4 flex items-center justify-between border-t border-base-200">
            <span class="text-sm text-base-content/70">
              {gettext("Total: %{count}", count: @total)} — {gettext("Page %{page}", page: @page)}
            </span>
            <div class="flex gap-2">
              <button :if={@page > 1} phx-click="prev_page" class="btn btn-sm">
                {gettext("Previous")}
              </button>
              <button
                :if={@events != [] and length(@events) == @page_size}
                phx-click="next_page"
                class="btn btn-sm"
              >
                {gettext("Next")}
              </button>
            </div>
          </div>
        </div>
      </div>

      <div
        :if={@selected}
        class="fixed inset-0 z-50 flex items-center justify-center"
        id="audit-detail-modal"
      >
        <div class="fixed inset-0 bg-black/50" phx-click="close_detail"></div>
        <div class="relative bg-base-100 rounded-lg shadow-xl max-w-2xl w-full mx-4 max-h-[80vh] overflow-auto p-6">
          <div class="flex justify-between items-start">
            <h3 class="text-lg font-semibold">{@selected.action} — {@selected.entity_type}</h3>
            <button phx-click="close_detail" class="btn btn-ghost btn-sm">✕</button>
          </div>
          <div class="mt-4 space-y-3 text-sm">
            <p>
              <span class="font-medium">{gettext("Entity:")}</span> {@selected.entity_type} / {@selected.entity_id}
            </p>
            <p>
              <span class="font-medium">{gettext("Actor:")}</span> {(@selected.actor &&
                                                                       @selected.actor.email) ||
                @selected.actor_type}
              <span class="text-base-content/50">({@selected.actor_type})</span>
            </p>
            <p>
              <span class="font-medium">{gettext("Time:")}</span> {Calendar.strftime(
                @selected.inserted_at,
                "%Y-%m-%d %H:%M:%S UTC"
              )}
            </p>
            <p :if={@selected.ip}><span class="font-medium">{gettext("IP:")}</span> {@selected.ip}</p>
            <p :if={@selected.user_agent}>
              <span class="font-medium">{gettext("User Agent:")}</span> {@selected.user_agent}
            </p>
            <div class="mt-4">
              <h4 class="font-medium">{gettext("Metadata")}</h4>
              <pre
                class="mt-2 bg-base-200 p-3 rounded text-xs overflow-auto"
                phx-no-curly-interpolation
              >{Jason.encode!(@selected.metadata, pretty: true)}</pre>
            </div>
            <div :if={@selected.metadata["before"] || @selected.metadata[:before]} class="mt-2">
              <h4 class="font-medium">{gettext("Before")}</h4>
              <pre
                class="mt-2 bg-base-200 p-3 rounded text-xs overflow-auto"
                phx-no-curly-interpolation
              >{Jason.encode!(@selected.metadata["before"] || @selected.metadata[:before] || %{}, pretty: true)}</pre>
            </div>
            <div :if={@selected.metadata["after"] || @selected.metadata[:after]} class="mt-2">
              <h4 class="font-medium">{gettext("After")}</h4>
              <pre
                class="mt-2 bg-base-200 p-3 rounded text-xs overflow-auto"
                phx-no-curly-interpolation
              >{Jason.encode!(@selected.metadata["after"] || @selected.metadata[:after] || %{}, pretty: true)}</pre>
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  def handle_event("filter", params, socket) do
    filters = build_filters(params, %{})

    {:noreply, socket |> assign(filters: filters, page: 1) |> load_events() |> stream_events()}
  end

  def handle_event("clear_filters", _params, socket) do
    {:noreply,
     socket
     |> assign(
       filters: %{
         "action" => "",
         "entity_type" => "",
         "search" => "",
         "actor_id" => "",
         "from" => "",
         "to" => ""
       },
       page: 1
     )
     |> load_events()
     |> stream_events()}
  end

  def handle_event("prev_page", _params, socket) do
    page = max(1, socket.assigns.page - 1)
    {:noreply, socket |> assign(page: page) |> load_events() |> stream_events()}
  end

  def handle_event("next_page", _params, socket) do
    {:noreply,
     socket |> assign(page: socket.assigns.page + 1) |> load_events() |> stream_events()}
  end

  def handle_event("show_detail", %{"id" => id}, socket) do
    event =
      Enum.find(socket.assigns.events, &(&1.id == id)) ||
        Treby.Repo.get!(Treby.Audit.AuditEvent, id) |> Treby.Repo.preload(:actor)

    {:noreply, assign(socket, selected: event)}
  end

  def handle_event("close_detail", _params, socket) do
    {:noreply, assign(socket, selected: nil)}
  end

  defp stream_events(socket) do
    socket |> stream(:events, socket.assigns.events, reset: true)
  end
end
