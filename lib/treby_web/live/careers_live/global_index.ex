defmodule TrebyWeb.CareersLive.GlobalIndex do
  use TrebyWeb, :live_view

  alias Treby.Jobs

  def mount(_params, session, socket) do
    socket = set_locale_from_session(socket, session)
    jobs = Jobs.list_all_visible_jobs()

    {:ok,
     socket
     |> assign(jobs: jobs)
     |> assign(search_query: "")
     |> assign(search_form: to_form(%{"query" => ""}, as: :search))}
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-base-200">
      <div class="max-w-4xl mx-auto py-12 px-4">
        <h1 class="text-4xl font-bold text-base-content text-center mb-8">All Open Positions</h1>

        <div class="mb-8">
          <.form for={@search_form} phx-submit="search" class="flex gap-2">
            <input
              type="text"
              name="query"
              value={@search_query}
              placeholder="Search across all companies..."
              class="input flex-1"
            />
            <.button type="submit" class="px-6">Search</.button>
          </.form>
        </div>

        <div :if={@jobs == []} class="text-center py-12 text-base-content/50">
          <%= if @search_query != "" do %>
            No positions match your search.
          <% else %>
            No open positions available.
          <% end %>
        </div>

        <div class="space-y-4">
          <.link
            :for={job <- @jobs}
            navigate={~p"/#{job.tenant.slug}/careers/#{job.id}"}
            class="block bg-base-100 rounded-lg shadow p-6 hover:shadow-md transition-shadow"
          >
            <div class="flex items-start justify-between">
              <div>
                <h3 class="text-xl font-semibold text-base-content">{job.title}</h3>
                <p class="text-sm text-base-content/50">{job.tenant.name}</p>
              </div>
              <p :if={job.salary_range} class="text-base-content/70">{job.salary_range}</p>
            </div>
          </.link>
        </div>
      </div>
    </div>
    """
  end

  def handle_event("search", %{"query" => query}, socket) do
    jobs =
      if String.trim(query) == "" do
        Jobs.list_all_visible_jobs()
      else
        Jobs.search_all_visible_jobs(query)
      end

    {:noreply,
     socket
     |> assign(jobs: jobs)
     |> assign(search_query: query)}
  end
end
