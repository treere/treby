defmodule TrebyWeb.InterviewsLive.Index do
  use TrebyWeb, :live_view

  alias Treby.{Accounts, Interviews}

  def mount(_params, session, socket) do
    socket = set_locale_from_session(socket, session)
    user = Accounts.get_user!(session["user_id"])
    tenant = Treby.Tenants.get_tenant!(session["tenant_id"])
    users = Accounts.list_users(tenant.id)

    socket =
      socket
      |> assign(current_user: user, current_tenant: tenant)
      |> assign(page_title: "Interviews")
      |> assign(view: "all")
      |> assign(filter_interviewer_id: nil)
      |> assign(users: users)
      |> load_interviews()

    {:ok, socket}
  end

  def handle_params(%{"view" => view}, _url, socket) do
    {:noreply,
     socket
     |> assign(view: view)
     |> load_interviews()}
  end

  def handle_params(_params, _url, socket) do
    {:noreply, load_interviews(socket)}
  end

  def handle_event("set_view", %{"view" => view}, socket) do
    {:noreply,
     socket
     |> assign(view: view)
     |> assign(filter_interviewer_id: nil)
     |> load_interviews()
     |> push_patch(to: ~p"/app/interviews?view=#{view}")}
  end

  def handle_event("filter_interviewer", %{"interviewer_id" => interviewer_id}, socket) do
    filter_id = if interviewer_id == "", do: nil, else: interviewer_id

    {:noreply,
     socket
     |> assign(filter_interviewer_id: filter_id)
     |> load_interviews()}
  end

  def handle_event("cancel_interview", %{"id" => event_id}, socket) do
    event = Interviews.get_event!(event_id)

    case Interviews.cancel_interview(event) do
      {:ok, _event} ->
        {:noreply,
         socket
         |> put_flash(:info, "Interview cancelled")
         |> load_interviews()}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to cancel interview")}
    end
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_user} locale={@locale}>
      <div class="p-8 max-w-6xl mx-auto">
        <div class="flex items-center justify-between mb-8">
          <div>
            <h1 class="text-2xl font-bold text-gray-900">Interviews</h1>
            <p class="mt-1 text-sm text-gray-500">Manage and view all scheduled interviews</p>
          </div>
          <div class="flex items-center gap-3">
            <div class="flex gap-2">
              <button
                phx-click="set_view"
                phx-value-view="all"
                class={[
                  "px-4 py-2 text-sm rounded-md transition-colors",
                  if(@view == "all",
                    do: "bg-blue-600 text-white",
                    else: "bg-white text-gray-700 border hover:bg-gray-50"
                  )
                ]}
              >
                All
              </button>
              <button
                phx-click="set_view"
                phx-value-view="my"
                class={[
                  "px-4 py-2 text-sm rounded-md transition-colors",
                  if(@view == "my",
                    do: "bg-blue-600 text-white",
                    else: "bg-white text-gray-700 border hover:bg-gray-50"
                  )
                ]}
              >
                My Interviews
              </button>
            </div>

            <%= if @view == "all" do %>
              <select
                phx-change="filter_interviewer"
                name="interviewer_id"
                class="px-3 py-2 text-sm border border-gray-300 rounded-md bg-white text-gray-700"
              >
                <option value="">All Interviewers</option>
                <%= for user <- @users do %>
                  <option
                    value={user.id}
                    selected={@filter_interviewer_id == user.id}
                  >
                    {user.name}
                  </option>
                <% end %>
              </select>
            <% end %>
          </div>
        </div>

        <div :if={@interviews == []} class="text-center py-12 bg-white rounded-lg border">
          <p class="text-gray-500">No interviews scheduled yet</p>
        </div>

        <div :if={@interviews != []} class="space-y-3">
          <%= for event <- @interviews do %>
            <div class="bg-white rounded-lg border p-4 hover:shadow-sm transition-shadow">
              <div class="flex items-start justify-between">
                <div class="flex-1">
                  <div class="flex items-center gap-3 mb-2">
                    <h3 class="font-medium text-gray-900">
                      {event.application.candidate.name}
                    </h3>
                    <span class="text-sm text-gray-500">for</span>
                    <span class="font-medium text-gray-700">
                      {event.application.job.title}
                    </span>
                  </div>

                  <div class="flex items-center gap-4 text-sm text-gray-500">
                    <span class="flex items-center gap-1">
                      <.icon name="hero-calendar" class="w-4 h-4" />
                      {Elixir.Calendar.strftime(event.start_at_utc, "%B %d, %Y")}
                    </span>
                    <span class="flex items-center gap-1">
                      <.icon name="hero-clock" class="w-4 h-4" />
                      {Elixir.Calendar.strftime(event.start_at_utc, "%H:%M")} - {Elixir.Calendar.strftime(
                        event.end_at_utc,
                        "%H:%M"
                      )}
                    </span>
                    <span class="flex items-center gap-1">
                      <.icon name="hero-user" class="w-4 h-4" />
                      {event.interviewer.name}
                    </span>
                  </div>
                </div>

                <div class="flex items-center gap-2">
                  <%= if event.video_conf_url do %>
                    <a
                      href={event.video_conf_url}
                      target="_blank"
                      class="px-3 py-1 text-sm bg-green-50 text-green-700 rounded-md hover:bg-green-100"
                    >
                      Join Meet
                    </a>
                  <% end %>
                  <button
                    phx-click="cancel_interview"
                    phx-value-id={event.id}
                    data-confirm="Are you sure you want to cancel this interview?"
                    class="px-3 py-1 text-sm text-red-600 hover:bg-red-50 rounded-md"
                  >
                    Cancel
                  </button>
                </div>
              </div>
            </div>
          <% end %>
        </div>
      </div>
    </Layouts.app>
    """
  end

  defp load_interviews(socket) do
    user = socket.assigns.current_user
    tenant_id = socket.assigns.current_tenant.id

    interviews =
      case socket.assigns.view do
        "my" ->
          Interviews.list_upcoming_for_user(user.id)

        _ ->
          base = Interviews.list_upcoming_for_tenant(tenant_id)

          if socket.assigns.filter_interviewer_id do
            Enum.filter(base, &(&1.interviewer_id == socket.assigns.filter_interviewer_id))
          else
            base
          end
      end

    assign(socket, interviews: interviews)
  end
end
