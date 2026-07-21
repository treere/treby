defmodule TrebyWeb.CareersLive.Show do
  use TrebyWeb, :live_view

  alias Treby.{Tenants, Jobs, Careers}

  def mount(%{"tenant_slug" => tenant_slug, "job_id" => job_id}, session, socket) do
    socket = set_locale_from_session(socket, session)
    tenant = Tenants.get_tenant_by_slug!(tenant_slug)
    job = Jobs.get_job!(tenant.id, job_id)
    career_page = Careers.get_published_career_page_by_tenant(tenant.id)

    {:ok,
     socket
     |> assign(tenant: tenant)
     |> assign(job: job)
     |> assign(career_page: career_page)}
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-50">
      <div class="max-w-3xl mx-auto py-12 px-4">
        <.link navigate={~p"/#{@tenant.slug}/careers"} class="text-blue-600 hover:text-blue-900">
          &larr; Back to all positions
        </.link>

        <div class="mt-8 bg-white rounded-lg shadow p-8">
          <img
            :if={@career_page && @career_page.logo_url}
            src={@career_page.logo_url}
            class="h-12 mb-4"
            alt={@tenant.name}
          />

          <h1 class="text-3xl font-bold text-gray-900">{@job.title}</h1>

          <p :if={@job.salary_range} class="mt-2 text-gray-600">{@job.salary_range}</p>

          <div class="mt-8 prose max-w-none">
            <p class="whitespace-pre-wrap text-gray-700">{@job.description}</p>
          </div>

          <.link
            navigate={~p"/#{@tenant.slug}/careers/#{@job.id}/apply"}
            class="mt-8 inline-block px-6 py-3 text-white font-semibold rounded-lg hover:opacity-90"
            style={"background-color: #{@career_page && @career_page.primary_color || "#3b82f6"}"}
          >
            Apply Now
          </.link>
        </div>
      </div>
    </div>
    """
  end
end
