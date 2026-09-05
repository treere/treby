defmodule TrebyWeb.CareersLive.Index do
  use TrebyWeb, :live_view

  alias Treby.{Tenants, Careers, Jobs}

  def mount(%{"tenant_slug" => tenant_slug}, session, socket) do
    socket = set_locale_from_session(socket, session)
    tenant = Tenants.get_tenant_by_slug!(tenant_slug)
    career_page = Careers.get_published_career_page_by_tenant(tenant.id)
    jobs = Jobs.list_visible_jobs(tenant.id)
    applied_job_ids = applied_job_ids_for_session(session, tenant.id)

    {:ok,
     socket
     |> assign(tenant: tenant)
     |> assign(career_page: career_page)
     |> assign(jobs: jobs)
     |> assign(applied_job_ids: applied_job_ids)
     |> assign(search_query: "")
     |> assign(search_form: to_form(%{"query" => ""}, as: :search))}
  end

  defp applied_job_ids_for_session(session, tenant_id) do
    with cid when is_binary(cid) <- session["candidate_id"],
         ^tenant_id <- session["candidate_tenant_id"] do
      Treby.Pipeline.list_applications_for_candidate(tenant_id, cid)
      |> Enum.map(& &1.job_id)
      |> MapSet.new()
    else
      _ -> MapSet.new()
    end
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-zinc-50 dark:bg-zinc-800">
      <div class="max-w-4xl mx-auto py-12 px-4">
        <div class="text-center mb-12">
          <img
            :if={@career_page && @career_page.logo_url}
            src={@career_page.logo_url}
            class="h-16 mx-auto mb-4"
            alt={@tenant.name}
          />
          <h1 class="text-4xl font-bold text-zinc-900 dark:text-zinc-100">
            {(@career_page && @career_page.title) || @tenant.name}
          </h1>
          <p
            :if={@career_page && @career_page.description}
            class="mt-4 text-lg text-zinc-500 dark:text-zinc-400"
          >
            {@career_page.description}
          </p>
        </div>

        <div class="mb-8">
          <.form for={@search_form} phx-submit="search" class="flex gap-2">
            <input
              type="text"
              name="query"
              value={@search_query}
              placeholder={gettext("Search positions...")}
              class="input flex-1"
            />
            <.button type="submit" class="px-6">{gettext("Search")}</.button>
          </.form>
        </div>

        <.page_header title={gettext("Open Positions")} />

        <div :if={@jobs == []}>
          <.empty_state
            :if={@search_query != ""}
            icon="hero-magnifying-glass"
            title={gettext("No positions match your search.")}
            description={gettext("Try a different keyword.")}
          />
          <.empty_state
            :if={@search_query == ""}
            icon="hero-briefcase"
            title={gettext("No open positions at this time.")}
            description={gettext("Check back later for new opportunities.")}
          />
        </div>

        <div class="space-y-4">
          <.link
            :for={job <- @jobs}
            navigate={~p"/#{@tenant.slug}/careers/#{job.id}"}
            class="block"
          >
            <.card class="hover:shadow-md transition-shadow">
              <div class="flex items-start justify-between gap-2">
                <h3 class="text-xl font-semibold text-zinc-900 dark:text-zinc-100">{job.title}</h3>
                <.badge
                  :if={MapSet.member?(@applied_job_ids, job.id)}
                  variant="success"
                  class="shrink-0"
                >
                  {gettext("Applied ✓")}
                </.badge>
              </div>
              <div class="mt-2 flex flex-wrap items-center gap-2 text-sm text-zinc-500 dark:text-zinc-400">
                <span :if={job.salary_range}>{job.salary_range}</span>
                <span :if={job.location} class="inline-flex items-center gap-1">
                  <.icon name="hero-map-pin" class="w-4 h-4" /> {job.location}
                </span>
                <.badge :if={job.employment_type} variant="default">
                  {Treby.Jobs.Job.employment_type_label(job.employment_type)}
                </.badge>
                <.badge :if={job.workplace_type} variant="default">
                  {Treby.Jobs.Job.workplace_type_label(job.workplace_type)}
                </.badge>
              </div>
            </.card>
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
