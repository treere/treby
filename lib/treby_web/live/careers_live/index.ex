defmodule TrebyWeb.CareersLive.Index do
  use TrebyWeb, :live_view

  alias Treby.{Tenants, Careers, Jobs}

  def mount(%{"tenant_slug" => tenant_slug}, session, socket) do
    socket = set_locale_from_session(socket, session)
    tenant = Tenants.get_tenant_by_slug(tenant_slug)

    {:ok,
     socket
     |> assign(tenant: tenant)
     |> assign(career_page: tenant && Careers.get_career_page_by_tenant(tenant.id))
     |> assign(
       applied_job_ids:
         if(tenant, do: applied_job_ids_for_session(session, tenant.id), else: MapSet.new())
     )
     |> assign(jobs: [])
     |> assign(search_query: "")
     |> assign(search_form: to_form(%{"query" => ""}, as: :search))}
  end

  def handle_params(_params, _uri, %{assigns: %{tenant: nil}} = socket), do: {:noreply, socket}

  def handle_params(params, _uri, socket) do
    query = params["query"] || ""

    {:noreply,
     socket
     |> assign(jobs: load_jobs(socket.assigns.tenant.id, query))
     |> assign(search_query: query)
     |> assign(search_form: to_form(%{"query" => query}, as: :search))}
  end

  defp load_jobs(tenant_id, query) do
    if String.trim(query) == "" do
      Jobs.list_visible_jobs(tenant_id)
    else
      Jobs.search_visible_jobs(tenant_id, query)
    end
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
      <Layouts.public_header locale={@locale} />
      <div class="max-w-4xl mx-auto py-12 px-4">
        <div :if={is_nil(@tenant)} class="max-w-lg mx-auto text-center">
          <.card class="shadow-sm">
            <div class="py-6">
              <.icon
                name="hero-building-office-2"
                class="w-14 h-14 mx-auto text-zinc-300 dark:text-zinc-600"
              />
              <h1 class="mt-4 text-2xl font-bold text-zinc-900 dark:text-zinc-100">
                {gettext("We couldn't find that company")}
              </h1>
              <p class="mt-2 text-sm text-zinc-500 dark:text-zinc-400">
                {gettext(
                  "The company you're looking for doesn't exist or has moved. Browse all open positions instead."
                )}
              </p>
              <.button variant="primary" navigate={~p"/careers"} class="mt-6">
                {gettext("Browse all open positions")}
              </.button>
              <div class="mt-3">
                <.link
                  navigate={~p"/"}
                  class="text-sm font-medium text-zinc-500 dark:text-zinc-400 hover:text-zinc-900 dark:hover:text-zinc-100"
                >
                  {gettext("Go to homepage")}
                </.link>
              </div>
            </div>
          </.card>
        </div>

        <%= if @tenant do %>
          <div class="text-center mb-12">
            <h1 class="text-4xl font-bold text-zinc-900 dark:text-zinc-100">
              {(@career_page && @career_page.title) || @tenant.name}
            </h1>
            <p
              :if={@career_page && @career_page.description not in [nil, ""]}
              class="mt-4 text-lg text-zinc-500 dark:text-zinc-400"
            >
              {@career_page.description}
            </p>
          </div>

          <.markdown
            :if={@career_page && @career_page.about not in [nil, ""]}
            text={@career_page.about}
            class="max-w-3xl mx-auto mb-12"
          />

          <div class="mb-8">
            <.form for={@search_form} phx-submit="search" class="flex gap-2">
              <input
                type="text"
                name="query"
                value={@search_query}
                placeholder={gettext("Search positions...")}
                class="flex-1 rounded-lg border border-zinc-200 dark:border-zinc-700 bg-white dark:bg-zinc-800 px-3 py-2 text-sm text-zinc-900 dark:text-zinc-100 placeholder:text-zinc-400 dark:placeholder:text-zinc-400 focus:outline-none focus:ring-2 focus:ring-orange-500"
              />
              <.button type="submit" class="px-6" loading_text={gettext("Searching...")}>{gettext(
                "Search"
              )}</.button>
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
        <% end %>
      </div>
    </div>
    """
  end

  def handle_event("search", %{"query" => query}, socket) do
    {:noreply, push_patch(socket, to: careers_path(socket.assigns.tenant.slug, query))}
  end

  defp careers_path(slug, query) do
    base = "/#{slug}/careers"

    case String.trim(query) do
      "" -> base
      q -> base <> "?" <> URI.encode_query(%{"query" => q})
    end
  end
end
