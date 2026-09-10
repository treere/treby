defmodule TrebyWeb.JobsLive.Index do
  use TrebyWeb, :live_view

  import Ecto.Query, warn: false

  alias Treby.{Accounts, Tenants, Jobs, JobViews}
  alias Treby.Repo

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

    candidate_counts = application_counts_by_job(tenant.id)
    view_summaries = JobViews.summaries_for_tenant(tenant.id)

    {:ok,
     socket
     |> assign(current_user: user, current_tenant: tenant)
     |> assign(candidate_counts: candidate_counts)
     |> assign(view_summaries: view_summaries)
     |> assign(filter: "all")}
  end

  def handle_params(params, uri, socket) do
    request_path = URI.parse(uri).path || "/app/jobs"

    {:noreply,
     socket
     |> assign(request_path: request_path)
     |> load_page(params["page"] || 1)}
  end

  defp load_page(socket, page) do
    %{current_tenant: tenant, filter: filter} = socket.assigns

    status = if filter in ["open", "closed"], do: filter, else: nil

    {entries, page_info} = Jobs.list_jobs(tenant.id, status: status, page: page)

    socket
    |> assign(jobs: entries)
    |> assign(page_info: page_info)
    |> assign(page: page_info.page)
  end

  defp page_url(path, filter, page) do
    params =
      %{page: page, filter: filter}
      |> Enum.reject(fn {_k, v} -> v in [nil, "", "all"] end)
      |> Map.new()

    "#{path}?#{URI.encode_query(params)}"
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_user} locale={@locale}>
      <div class="p-8">
        <.page_header title={gettext("Jobs")}>
          <:actions>
            <.button variant="primary" navigate={~p"/app/jobs/new"}>
              <.icon name="hero-plus" class="w-4 h-4" /> {gettext("New Job")}
            </.button>
          </:actions>
        </.page_header>

        <div class="flex gap-2 mb-6">
          <button
            phx-click="filter_jobs"
            phx-value-filter="all"
            class={"px-3 py-1.5 rounded-lg text-sm font-medium #{if @filter == "all", do: "bg-blue-100 dark:bg-blue-900 text-blue-800 dark:text-blue-100", else: "bg-zinc-50 dark:bg-zinc-800 text-zinc-500 dark:text-zinc-400 hover:bg-zinc-200 dark:hover:bg-zinc-700"}"}
          >
            {gettext("All")}
          </button>
          <button
            phx-click="filter_jobs"
            phx-value-filter="open"
            class={"px-3 py-1.5 rounded-lg text-sm font-medium #{if @filter == "open", do: "bg-green-100 dark:bg-green-900 text-green-800 dark:text-green-100", else: "bg-zinc-50 dark:bg-zinc-800 text-zinc-500 dark:text-zinc-400 hover:bg-zinc-200 dark:hover:bg-zinc-700"}"}
          >
            {gettext("Open")}
          </button>
          <button
            phx-click="filter_jobs"
            phx-value-filter="closed"
            class={"px-3 py-1.5 rounded-lg text-sm font-medium #{if @filter == "closed", do: "bg-zinc-200 dark:bg-zinc-700 text-zinc-900 dark:text-zinc-100/90", else: "bg-zinc-50 dark:bg-zinc-800 text-zinc-500 dark:text-zinc-400 hover:bg-zinc-200 dark:hover:bg-zinc-700"}"}
          >
            {gettext("Closed")}
          </button>
        </div>

        <div class="bg-white dark:bg-zinc-800 rounded-xl border border-zinc-200 dark:border-zinc-700 shadow-sm overflow-hidden">
          <table class="min-w-full divide-y divide-zinc-100 dark:divide-zinc-700">
            <thead class="bg-zinc-50 dark:bg-zinc-800">
              <tr>
                <th class="px-6 py-3 text-left text-xs font-medium text-zinc-500 dark:text-zinc-400 uppercase tracking-wider">
                  {gettext("Title")}
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-zinc-500 dark:text-zinc-400 uppercase tracking-wider">
                  {gettext("Salary")}
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-zinc-500 dark:text-zinc-400 uppercase tracking-wider">
                  {gettext("Status")}
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-zinc-500 dark:text-zinc-400 uppercase tracking-wider">
                  {gettext("Public")}
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-zinc-500 dark:text-zinc-400 uppercase tracking-wider">
                  {gettext("Views")}
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-zinc-500 dark:text-zinc-400 uppercase tracking-wider">
                  {gettext("Candidates")}
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-zinc-500 dark:text-zinc-400 uppercase tracking-wider">
                  {gettext("Actions")}
                </th>
              </tr>
            </thead>
            <tbody class="bg-white dark:bg-zinc-800 divide-y divide-zinc-100 dark:divide-zinc-700">
              <tr
                :for={job <- @jobs}
                class="hover:bg-zinc-50 dark:hover:bg-zinc-700/50 transition-colors"
              >
                <td class="px-6 py-4 whitespace-nowrap">
                  <.link
                    navigate={~p"/app/jobs/#{job.id}"}
                    class="text-blue-600 dark:text-blue-400 hover:text-blue-900 dark:hover:text-blue-300 font-medium"
                  >
                    {job.title}
                  </.link>
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-zinc-500 dark:text-zinc-400">
                  {job.salary_range || "-"}
                </td>
                <td class="px-6 py-4 whitespace-nowrap">
                  <.badge variant={if job.status == "open", do: "success", else: "default"}>
                    {job.status}
                  </.badge>
                </td>
                <td class="px-6 py-4 whitespace-nowrap">
                  <button
                    phx-click="toggle_visibility"
                    phx-value-job_id={job.id}
                    disabled={job.status != "open"}
                    class={"inline-flex items-center gap-1 px-2 py-1 rounded text-xs font-medium #{if job.visible, do: "bg-blue-100 dark:bg-blue-900 text-blue-800 dark:text-blue-100 hover:bg-blue-200 dark:hover:bg-blue-800", else: "bg-zinc-50 dark:bg-zinc-800 text-zinc-500 dark:text-zinc-400 hover:bg-zinc-200 dark:hover:bg-zinc-700"} #{if job.status != "open", do: "opacity-50 cursor-not-allowed"}"}
                  >
                    <.icon
                      name={if job.visible, do: "hero-globe-alt", else: "hero-lock-closed"}
                      class="w-3 h-3"
                    />
                    {if job.visible, do: gettext("Public"), else: gettext("Private")}
                  </button>
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-zinc-500 dark:text-zinc-400">
                  <% summary =
                    Map.get(@view_summaries, job.id, %{total_views: 0, views_last_7_days: 0}) %>
                  <%= if summary.total_views > 0 do %>
                    <span class="inline-flex items-center gap-1 text-xs">
                      <.icon name="hero-eye" class="w-3 h-3 text-zinc-500 dark:text-zinc-400" />
                      {summary.total_views} · {gettext("%{count} last 7d",
                        count: summary.views_last_7_days
                      )}
                    </span>
                  <% else %>
                    <span class="text-xs text-zinc-500 dark:text-zinc-400">{gettext("No views yet")}</span>
                  <% end %>
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-zinc-500 dark:text-zinc-400">
                  {Map.get(@candidate_counts, job.id, 0)}
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-sm">
                  <.link
                    navigate={~p"/app/pipeline/#{job.id}"}
                    class="text-blue-600 dark:text-blue-400 hover:text-blue-900 dark:hover:text-blue-300 mr-3 inline-flex items-center gap-1"
                  >
                    <.icon name="hero-arrow-top-right-on-square" class="w-4 h-4" /> {gettext(
                      "Pipeline"
                    )}
                  </.link>
                  <button
                    phx-click="toggle_status"
                    phx-value-job_id={job.id}
                    class="text-yellow-600 hover:text-yellow-900 inline-flex items-center gap-1"
                  >
                    <.icon
                      name={if job.status == "open", do: "hero-x-mark", else: "hero-arrow-path"}
                      class="w-4 h-4"
                    />
                    {if job.status == "open", do: gettext("Close"), else: gettext("Reopen")}
                  </button>
                </td>
              </tr>
            </tbody>
          </table>
          <div class="mt-4">
            <.pagination
              id="pagination"
              page={@page_info.page}
              total_pages={@page_info.total_pages}
              total_count={@page_info.total_count}
              page_size={@page_info.page_size}
              patch={fn p -> page_url(@request_path, @filter, p) end}
            />
          </div>
          <.empty_state
            :if={@jobs == []}
            icon="hero-briefcase"
            title={gettext("No job postings yet")}
            description={
              gettext(
                "Job postings let candidates apply through your career page and help you track applicants through each stage of your hiring pipeline."
              )
            }
          >
            <:cta>
              <.button variant="primary" navigate={~p"/app/jobs/new"}>
                {gettext("Create your first job")}
              </.button>
            </:cta>
          </.empty_state>
        </div>
      </div>
    </Layouts.app>
    """
  end

  def handle_event("paginate", %{"page" => page}, socket) do
    {:noreply,
     push_patch(socket, to: page_url(socket.assigns.request_path, socket.assigns.filter, page))}
  end

  def handle_event("filter_jobs", %{"filter" => filter}, socket) do
    {:noreply,
     socket
     |> assign(filter: filter)
     |> load_page(1)}
  end

  def handle_event("toggle_status", %{"job_id" => job_id}, socket) do
    job = Jobs.get_job!(socket.assigns.current_tenant.id, job_id)
    new_status = if job.status == "open", do: "closed", else: "open"

    case Jobs.update_job(job, %{status: new_status}) do
      {:ok, _job} ->
        {:noreply, load_page(socket, socket.assigns.page)}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, gettext("Failed to update job status"))}
    end
  end

  def handle_event("toggle_visibility", %{"job_id" => job_id}, socket) do
    job = Jobs.get_job!(socket.assigns.current_tenant.id, job_id)
    new_visible = !job.visible

    case Jobs.update_job(job, %{visible: new_visible}) do
      {:ok, _job} ->
        {:noreply, load_page(socket, socket.assigns.page)}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, gettext("Failed to update visibility"))}
    end
  end

  defp application_counts_by_job(tenant_id) do
    Treby.Pipeline.Application
    |> where([a], a.tenant_id == ^tenant_id)
    |> group_by([a], a.job_id)
    |> select([a], %{job_id: a.job_id, count: count(a.id)})
    |> Repo.all()
    |> Map.new(fn %{job_id: jid, count: n} -> {jid, n} end)
  end
end
