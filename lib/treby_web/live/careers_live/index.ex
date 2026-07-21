defmodule TrebyWeb.CareersLive.Index do
  use TrebyWeb, :live_view

  alias Treby.{Tenants, Careers, Jobs}

  def mount(%{"tenant_slug" => tenant_slug}, session, socket) do
    socket = set_locale_from_session(socket, session)
    tenant = Tenants.get_tenant_by_slug!(tenant_slug)
    career_page = Careers.get_published_career_page_by_tenant(tenant.id)
    jobs = Jobs.list_open_jobs(tenant.id)

    {:ok,
     socket
     |> assign(tenant: tenant)
     |> assign(career_page: career_page)
     |> assign(jobs: jobs)}
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-50">
      <div :if={@career_page} class="max-w-4xl mx-auto py-12 px-4">
        <div class="text-center mb-12">
          <img
            :if={@career_page.logo_url}
            src={@career_page.logo_url}
            class="h-16 mx-auto mb-4"
            alt={@tenant.name}
          />
          <h1 class="text-4xl font-bold text-gray-900">{@career_page.title}</h1>
          <p :if={@career_page.description} class="mt-4 text-lg text-gray-600">
            {@career_page.description}
          </p>
        </div>

        <h2 class="text-2xl font-semibold text-gray-800 mb-6">Open Positions</h2>

        <div class="space-y-4">
          <.link
            :for={job <- @jobs}
            navigate={~p"/#{@tenant.slug}/careers/#{job.id}"}
            class="block bg-white rounded-lg shadow p-6 hover:shadow-md transition-shadow"
          >
            <h3 class="text-xl font-semibold text-gray-900">{job.title}</h3>
            <p :if={job.salary_range} class="mt-2 text-gray-600">{job.salary_range}</p>
          </.link>
        </div>

        <div :if={@jobs == []} class="text-center py-12 text-gray-500">
          No open positions at this time.
        </div>
      </div>

      <div :if={!@career_page} class="max-w-4xl mx-auto py-12 px-4 text-center">
        <h1 class="text-4xl font-bold text-gray-900">{@tenant.name}</h1>
        <p class="mt-4 text-lg text-gray-600">Career page coming soon.</p>
      </div>
    </div>
    """
  end
end
