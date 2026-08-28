defmodule TrebyWeb.CareersLive.Index do
  use TrebyWeb, :live_view

  alias Treby.{Tenants, Careers, Jobs}

  def mount(%{"tenant_slug" => tenant_slug}, session, socket) do
    socket = set_locale_from_session(socket, session)
    tenant = Tenants.get_tenant_by_slug!(tenant_slug)
    career_page = Careers.get_published_career_page_by_tenant(tenant.id)
    jobs = Jobs.list_visible_jobs(tenant.id)

    {:ok,
     socket
     |> assign(tenant: tenant)
     |> assign(career_page: career_page)
     |> assign(jobs: jobs)
     |> assign(search_query: "")
     |> assign(search_form: to_form(%{"query" => ""}, as: :search))}
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-base-200">
      <div class="max-w-4xl mx-auto py-12 px-4">
        <div class="text-center mb-12">
          <img
            :if={@career_page && @career_page.logo_url}
            src={@career_page.logo_url}
            class="h-16 mx-auto mb-4"
            alt={@tenant.name}
          />
          <h1 class="text-4xl font-bold text-base-content">
            {(@career_page && @career_page.title) || @tenant.name}
          </h1>
          <p :if={@career_page && @career_page.description} class="mt-4 text-lg text-base-content/70">
            {@career_page.description}
          </p>
        </div>

        <div class="mb-8">
          <.form for={@search_form} phx-submit="search" class="flex gap-2">
            <input
              type="text"
              name="query"
              value={@search_query}
              placeholder="Search positions..."
              class="input flex-1"
            />
            <.button type="submit" class="px-6">Search</.button>
          </.form>
        </div>

        <h2 class="text-2xl font-semibold text-base-content/90 mb-6">Open Positions</h2>

        <div :if={@jobs == []} class="text-center py-12 text-base-content/50">
          <%= if @search_query != "" do %>
            No positions match your search.
          <% else %>
            No open positions at this time.
          <% end %>
        </div>

        <div class="space-y-4">
          <.link
            :for={job <- @jobs}
            navigate={~p"/#{@tenant.slug}/careers/#{job.id}"}
            class="block bg-base-100 rounded-lg shadow p-6 hover:shadow-md transition-shadow"
          >
            <h3 class="text-xl font-semibold text-base-content">{job.title}</h3>
            <p :if={job.salary_range} class="mt-2 text-base-content/70">{job.salary_range}</p>
          </.link>
        </div>
      </div>
    </div>
    """
  end

  def handle_event("search", %{"query" => query}, socket) do
    jobs =
      if String.trim(query) == "" do
        Jobs.list_visible_jobs(socket.assigns.tenant.id)
      else
        Jobs.search_visible_jobs(socket.assigns.tenant.id, query)
      end

    {:noreply,
     socket
     |> assign(jobs: jobs)
     |> assign(search_query: query)}
  end
end
