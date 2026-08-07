defmodule TrebyWeb.CareersLive.Show do
  use TrebyWeb, :live_view

  alias Treby.{Tenants, Jobs, Careers}

  def mount(%{"tenant_slug" => tenant_slug, "job_id" => job_id}, session, socket) do
    socket = set_locale_from_session(socket, session)
    tenant = Tenants.get_tenant_by_slug!(tenant_slug)

    job =
      try do
        Jobs.get_job!(tenant.id, job_id)
      rescue
        Ecto.NoResultsError -> nil
      end

    career_page = Careers.get_published_career_page_by_tenant(tenant.id)

    {:ok,
     socket
     |> assign(tenant: tenant)
     |> assign(job: job)
     |> assign(career_page: career_page)}
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-base-200">
      <div class="max-w-3xl mx-auto py-12 px-4">
        <.link navigate={~p"/#{@tenant.slug}/careers"} class="text-blue-600 hover:text-blue-900">
          &larr; Back to all positions
        </.link>

        <div :if={@job && @job.status == "open"} class="mt-8 bg-base-100 rounded-lg shadow p-8">
          <div :if={@career_page} class="flex items-center gap-4 mb-6">
            <img
              :if={@career_page.logo_url}
              src={@career_page.logo_url}
              class="h-12"
              alt={@tenant.name}
            />
            <div>
              <h2 class="text-lg font-semibold text-base-content">{@tenant.name}</h2>
              <p :if={@career_page.description} class="text-sm text-base-content/50">
                {@career_page.description}
              </p>
            </div>
          </div>

          <h1 class="text-3xl font-bold text-base-content">{@job.title}</h1>

          <p :if={@job.salary_range} class="mt-2 text-base-content/70">{@job.salary_range}</p>

          <div class="mt-8 prose max-w-none">
            <p class="whitespace-pre-wrap text-base-content/80">{@job.description}</p>
          </div>

          <.link
            navigate={~p"/#{@tenant.slug}/careers/#{@job.id}/apply"}
            class="mt-8 inline-block px-6 py-3 text-white font-semibold rounded-lg hover:opacity-90"
            style={"background-color: #{@career_page && @career_page.primary_color || "#3b82f6"}"}
          >
            Apply Now
          </.link>
        </div>

        <div
          :if={@job && @job.status != "open"}
          class="mt-8 bg-base-100 rounded-lg shadow p-8 text-center"
        >
          <h1 class="text-2xl font-bold text-base-content">This position is no longer available</h1>
          <p class="mt-4 text-base-content/70">
            The job you're looking for has been closed or removed.
          </p>
          <.link
            navigate={~p"/#{@tenant.slug}/careers"}
            class="mt-6 inline-block text-blue-600 hover:text-blue-900"
          >
            View other positions
          </.link>
        </div>

        <div :if={!@job} class="mt-8 bg-base-100 rounded-lg shadow p-8 text-center">
          <h1 class="text-2xl font-bold text-base-content">Position not found</h1>
          <p class="mt-4 text-base-content/70">
            The job you're looking for doesn't exist or has been removed.
          </p>
          <.link
            navigate={~p"/#{@tenant.slug}/careers"}
            class="mt-6 inline-block text-blue-600 hover:text-blue-900"
          >
            View other positions
          </.link>
        </div>
      </div>
    </div>
    """
  end
end
