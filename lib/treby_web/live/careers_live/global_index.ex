defmodule TrebyWeb.CareersLive.GlobalIndex do
  use TrebyWeb, :live_view

  alias Treby.Jobs

  def mount(_params, session, socket) do
    socket = set_locale_from_session(socket, session)
    jobs = Jobs.list_all_visible_jobs()
    applied_job_ids = applied_job_ids_for_session(session)

    {:ok,
     socket
     |> assign(jobs: jobs)
     |> assign(applied_job_ids: applied_job_ids)
     |> assign(search_query: "")
     |> assign(search_form: to_form(%{"query" => ""}, as: :search))}
  end

  defp applied_job_ids_for_session(session) do
    with cid when is_binary(cid) <- session["candidate_id"],
         tenant_id when is_binary(tenant_id) <- session["candidate_tenant_id"] do
      Treby.Pipeline.list_applications_for_candidate(tenant_id, cid)
      |> Enum.map(& &1.job_id)
      |> MapSet.new()
    else
      _ -> MapSet.new()
    end
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-base-200">
      <div class="max-w-4xl mx-auto py-12 px-4">
        <h1 class="text-4xl font-bold text-base-content text-center mb-8">
          {gettext("All Open Positions")}
        </h1>

        <div class="mb-8">
          <.form for={@search_form} phx-submit="search" class="flex gap-2">
            <input
              type="text"
              name="query"
              value={@search_query}
              placeholder={gettext("Search across all companies...")}
              class="input flex-1"
            />
            <.button type="submit" class="px-6">{gettext("Search")}</.button>
          </.form>
        </div>

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
            title={gettext("No open positions available.")}
          />
        </div>

        <div class="space-y-4">
          <.link
            :for={job <- @jobs}
            navigate={~p"/#{job.tenant.slug}/careers/#{job.id}"}
            class="block"
          >
            <.card class="hover:shadow-md transition-shadow">
              <div class="flex items-start justify-between gap-4">
                <div>
                  <div class="flex items-center gap-2">
                    <h3 class="text-xl font-semibold text-base-content">{job.title}</h3>
                    <.badge :if={MapSet.member?(@applied_job_ids, job.id)} variant="success">
                      {gettext("Applied ✓")}
                    </.badge>
                  </div>
                  <p class="text-sm text-base-content/50">{job.tenant.name}</p>
                  <div class="mt-1 flex flex-wrap items-center gap-2 text-sm text-base-content/70">
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
                </div>
                <p :if={job.salary_range} class="text-base-content/70 shrink-0">{job.salary_range}</p>
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
