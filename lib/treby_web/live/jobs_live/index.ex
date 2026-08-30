defmodule TrebyWeb.JobsLive.Index do
  use TrebyWeb, :live_view

  alias Treby.{Accounts, Tenants, Jobs, Customization, Pipeline, JobViews}
  alias Treby.Jobs.Job
  alias Treby.Repo

  def mount(params, session, socket) do
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

    jobs = Jobs.list_jobs(tenant.id)
    job_fields = Customization.list_custom_fields_for(tenant.id, "job")
    pipelines = Pipeline.list_pipelines(tenant.id)
    templates = Pipeline.list_templates(tenant.id)
    default_pipeline_id = Pipeline.default_pipeline_id(tenant.id)
    candidate_counts = application_counts_by_job(tenant.id)
    view_summaries = JobViews.summaries_for_tenant(tenant.id)

    {:ok,
     socket
     |> assign(current_user: user, current_tenant: tenant)
     |> assign(jobs: jobs)
     |> assign(candidate_counts: candidate_counts)
     |> assign(view_summaries: view_summaries)
     |> assign(job_fields: job_fields)
     |> assign(pipelines: pipelines)
     |> assign(templates: templates)
     |> assign(default_pipeline_id: default_pipeline_id)
     |> assign(filter: "all")
     |> assign(show_form: false)
     |> assign(form: to_form(Jobs.change_job(%Job{})))}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_user} locale={@locale}>
      <div class="p-8">
        <div class="flex justify-between items-center mb-8">
          <h1 class="text-2xl font-bold">Jobs</h1>
          <button
            phx-click="show_create_form"
            class="bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700 inline-flex items-center gap-1"
          >
            <.icon name="hero-plus" class="w-4 h-4" /> {gettext("New Job")}
          </button>
        </div>

        <div class="flex gap-2 mb-6">
          <button
            phx-click="filter_jobs"
            phx-value-filter="all"
            class={"px-3 py-1.5 rounded-lg text-sm font-medium #{if @filter == "all", do: "bg-blue-100 dark:bg-blue-900 text-blue-800 dark:text-blue-100", else: "bg-base-200 text-base-content/70 hover:bg-base-300"}"}
          >
            All
          </button>
          <button
            phx-click="filter_jobs"
            phx-value-filter="open"
            class={"px-3 py-1.5 rounded-lg text-sm font-medium #{if @filter == "open", do: "bg-green-100 dark:bg-green-900 text-green-800 dark:text-green-100", else: "bg-base-200 text-base-content/70 hover:bg-base-300"}"}
          >
            Open
          </button>
          <button
            phx-click="filter_jobs"
            phx-value-filter="closed"
            class={"px-3 py-1.5 rounded-lg text-sm font-medium #{if @filter == "closed", do: "bg-base-300 text-base-content/90", else: "bg-base-200 text-base-content/70 hover:bg-base-300"}"}
          >
            Closed
          </button>
        </div>

        <div :if={@show_form} class="mb-8 p-6 bg-base-100 rounded-lg shadow">
          <h2 class="text-lg font-semibold mb-4">Create Job</h2>
          <.form for={@form} id="job-form" phx-submit="create_job">
            <.input field={@form[:title]} type="text" label="Title" />
            <.input field={@form[:description]} type="textarea" label="Description" />
            <.input
              field={@form[:salary_range]}
              type="text"
              label="Salary Range"
              placeholder="$100k-$150k"
            />

            <.input
              field={@form[:pipeline_id]}
              type="select"
              label="Pipeline"
              options={Enum.map(@pipelines, &{&1.name, &1.id})}
              prompt="Default pipeline"
            />

            <div :if={@templates != []} class="mt-3">
              <label class="block text-sm font-medium text-base-content/80 mb-1">
                {gettext("Or start from a template")}
              </label>
              <.input
                name="template_id"
                type="select"
                options={Enum.map(@templates, &{&1.name, &1.id})}
                prompt={gettext("Select a template...")}
                label=""
              />
            </div>

            <div :if={@job_fields != []} class="mt-4 border-t pt-4">
              <h3 class="text-sm font-medium text-base-content/80 mb-3">Additional Information</h3>
              <div :for={field <- @job_fields} class="mb-3">
                <%= cond do %>
                  <% field.field_type == "select" -> %>
                    <.input
                      name={"custom_fields[#{field.id}]"}
                      type="select"
                      label={field.name}
                      options={field.options}
                      prompt="—"
                    />
                  <% field.field_type == "date" -> %>
                    <.input name={"custom_fields[#{field.id}]"} type="date" label={field.name} />
                  <% field.field_type == "number" -> %>
                    <.input name={"custom_fields[#{field.id}]"} type="number" label={field.name} />
                  <% field.field_type == "url" -> %>
                    <.input
                      name={"custom_fields[#{field.id}]"}
                      type="url"
                      label={field.name}
                      placeholder="https://"
                    />
                  <% true -> %>
                    <.input name={"custom_fields[#{field.id}]"} type="text" label={field.name} />
                <% end %>
              </div>
            </div>

            <div class="mt-4 flex gap-2">
              <.button type="submit">Create</.button>
              <.button type="button" phx-click="hide_create_form" class="bg-gray-500">Cancel</.button>
            </div>
          </.form>
        </div>

        <div class="bg-base-100 rounded-lg shadow overflow-hidden">
          <table class="min-w-full divide-y divide-gray-200">
            <thead class="bg-base-200">
              <tr>
                <th class="px-6 py-3 text-left text-xs font-medium text-base-content/50 uppercase tracking-wider">
                  Title
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-base-content/50 uppercase tracking-wider">
                  Salary
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-base-content/50 uppercase tracking-wider">
                  Status
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-base-content/50 uppercase tracking-wider">
                  Public
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-base-content/50 uppercase tracking-wider">
                  Views
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-base-content/50 uppercase tracking-wider">
                  Candidates
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-base-content/50 uppercase tracking-wider">
                  Actions
                </th>
              </tr>
            </thead>
            <tbody class="bg-base-100 divide-y divide-gray-200">
              <tr :for={job <- @jobs} class="hover:bg-base-200">
                <td class="px-6 py-4 whitespace-nowrap">
                  <.link
                    navigate={~p"/app/jobs/#{job.id}"}
                    class="text-blue-600 hover:text-blue-900 font-medium"
                  >
                    {job.title}
                  </.link>
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-base-content/70">
                  {job.salary_range || "-"}
                </td>
                <td class="px-6 py-4 whitespace-nowrap">
                  <span class={"px-2 inline-flex text-xs leading-5 font-semibold rounded-full #{if job.status == "open", do: "bg-green-100 dark:bg-green-900 text-green-800 dark:text-green-100", else: "bg-base-200 text-base-content/90"}"}>
                    {job.status}
                  </span>
                </td>
                <td class="px-6 py-4 whitespace-nowrap">
                  <button
                    phx-click="toggle_visibility"
                    phx-value-job_id={job.id}
                    disabled={job.status != "open"}
                    class={"inline-flex items-center gap-1 px-2 py-1 rounded text-xs font-medium #{if job.visible, do: "bg-blue-100 dark:bg-blue-900 text-blue-800 dark:text-blue-100 hover:bg-blue-200", else: "bg-base-200 text-base-content/50 hover:bg-base-300"} #{if job.status != "open", do: "opacity-50 cursor-not-allowed"}"}
                  >
                    <.icon
                      name={if job.visible, do: "hero-globe-alt", else: "hero-lock-closed"}
                      class="w-3 h-3"
                    />
                    {if job.visible, do: "Public", else: "Private"}
                  </button>
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-base-content/70">
                  <% summary =
                    Map.get(@view_summaries, job.id, %{total_views: 0, views_last_7_days: 0}) %>
                  <%= if summary.total_views > 0 do %>
                    <span class="inline-flex items-center gap-1 text-xs">
                      <.icon name="hero-eye" class="w-3 h-3 text-base-content/50" />
                      {summary.total_views} · {summary.views_last_7_days} last 7d
                    </span>
                  <% else %>
                    <span class="text-xs text-base-content/40">No views yet</span>
                  <% end %>
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-base-content/70">
                  {Map.get(@candidate_counts, job.id, 0)}
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-sm">
                  <.link
                    navigate={~p"/app/pipeline/#{job.id}"}
                    class="text-blue-600 hover:text-blue-900 mr-3 inline-flex items-center gap-1"
                  >
                    <.icon name="hero-arrow-top-right-on-square" class="w-4 h-4" /> Pipeline
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
                    {if job.status == "open", do: "Close", else: "Reopen"}
                  </button>
                </td>
              </tr>
            </tbody>
          </table>
          <.empty_state
            :if={@jobs == []}
            icon="hero-briefcase"
            title="No job postings yet"
            description="Job postings let candidates apply through your career page and help you track applicants through each stage of your hiring pipeline."
          >
            <:cta>
              <button
                type="button"
                phx-click="show_create_form"
                class="btn btn-primary"
              >
                {gettext("Create your first job")}
              </button>
            </:cta>
          </.empty_state>
        </div>
      </div>
    </Layouts.app>
    """
  end

  def handle_event("show_create_form", _, socket) do
    {:noreply, assign(socket, show_form: true)}
  end

  def handle_event("hide_create_form", _, socket) do
    {:noreply, assign(socket, show_form: false)}
  end

  def handle_event("filter_jobs", %{"filter" => filter}, socket) do
    jobs = Jobs.list_jobs(socket.assigns.current_tenant.id)

    filtered_jobs =
      case filter do
        "open" -> Enum.filter(jobs, &(&1.status == "open"))
        "closed" -> Enum.filter(jobs, &(&1.status == "closed"))
        _ -> jobs
      end

    {:noreply, assign(socket, jobs: filtered_jobs, filter: filter)}
  end

  def handle_event("create_job", params, socket) do
    job_params = Map.get(params, "job", %{})
    custom_fields_values = Map.get(params, "custom_fields", %{})
    template_id = Map.get(params, "template_id", "")

    pipeline_id =
      cond do
        template_id != "" ->
          # Clone template to create a new pipeline for this job
          template = Pipeline.get_pipeline!(template_id)

          {:ok, new_pipeline} =
            Pipeline.clone_template_to_pipeline(template, socket.assigns.current_tenant.id)

          new_pipeline.id

        Map.get(job_params, "pipeline_id") not in [nil, ""] ->
          Map.get(job_params, "pipeline_id")

        true ->
          Pipeline.default_pipeline_id(socket.assigns.current_tenant.id)
      end

    attrs =
      job_params
      |> Map.put("pipeline_id", pipeline_id)
      |> Map.put("tenant_id", socket.assigns.current_tenant.id)

    required_fields =
      Customization.list_custom_fields_for(socket.assigns.current_tenant.id, "job")
      |> Enum.filter(& &1.required)
      |> Enum.filter(fn field ->
        value = Map.get(custom_fields_values, to_string(field.id), "")
        value == "" or is_nil(value)
      end)

    if required_fields != [] do
      missing = Enum.map_join(required_fields, ", ", & &1.name)

      {:noreply,
       socket
       |> put_flash(:error, "Please fill in required fields: #{missing}")}
    else
      attrs = Map.put(attrs, "custom_fields", custom_fields_values)

      case Jobs.create_job(attrs) do
        {:ok, _job} ->
          jobs = Jobs.list_jobs(socket.assigns.current_tenant.id)
          view_summaries = JobViews.summaries_for_tenant(socket.assigns.current_tenant.id)

          {:noreply,
           socket
           |> assign(jobs: jobs, view_summaries: view_summaries, show_form: false)
           |> assign(form: to_form(Jobs.change_job(%Job{})))
           |> put_flash(:info, "Job created successfully")}

        {:error, changeset} ->
          {:noreply,
           socket
           |> assign(form: to_form(changeset))
           |> put_flash(:error, "Please review the errors below")}
      end
    end
  end

  def handle_event("toggle_status", %{"job_id" => job_id}, socket) do
    job = Jobs.get_job!(socket.assigns.current_tenant.id, job_id)
    new_status = if job.status == "open", do: "closed", else: "open"

    case Jobs.update_job(job, %{status: new_status}) do
      {:ok, _job} ->
        jobs = Jobs.list_jobs(socket.assigns.current_tenant.id)
        {:noreply, assign(socket, jobs: jobs)}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to update job status")}
    end
  end

  def handle_event("toggle_visibility", %{"job_id" => job_id}, socket) do
    job = Jobs.get_job!(socket.assigns.current_tenant.id, job_id)
    new_visible = !job.visible

    case Jobs.update_job(job, %{visible: new_visible}) do
      {:ok, _job} ->
        jobs = Jobs.list_jobs(socket.assigns.current_tenant.id)
        {:noreply, assign(socket, jobs: jobs)}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to update visibility")}
    end
  end

  defp application_counts_by_job(tenant_id) do
    import Ecto.Query

    Treby.Pipeline.Application
    |> where([a], a.tenant_id == ^tenant_id)
    |> group_by([a], a.job_id)
    |> select([a], %{job_id: a.job_id, count: count(a.id)})
    |> Repo.all()
    |> Map.new(fn %{job_id: jid, count: n} -> {jid, n} end)
  end
end
