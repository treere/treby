defmodule TrebyWeb.CandidatesLive.Index do
  use TrebyWeb, :live_view

  alias Treby.{Accounts, Tenants, Candidates, Pipeline, Jobs, Customization}
  alias Treby.Candidates.Candidate

  def mount(_params, session, socket) do
    socket = set_locale_from_session(socket, session)
    user = Accounts.get_user!(session["user_id"])
    tenant = Tenants.get_tenant!(session["tenant_id"])
    candidates = Candidates.list_candidates(tenant.id)
    candidate_fields = Customization.list_custom_fields_for(tenant.id, "candidate")
    jobs = Jobs.list_jobs(tenant.id)
    pipeline_stages = list_all_stages(tenant.id)

    candidates_with_counts =
      Enum.map(candidates, fn candidate ->
        applications = Pipeline.list_applications_for_candidate(tenant.id, candidate.id)
        Map.put(candidate, :application_count, length(applications))
      end)

    {:ok,
     socket
     |> assign(current_user: user, current_tenant: tenant)
     |> assign(candidates: candidates_with_counts)
     |> assign(candidate_fields: candidate_fields)
     |> assign(jobs: jobs)
     |> assign(pipeline_stages: pipeline_stages)
     |> assign(search: "")
     |> assign(filter_job_id: "")
     |> assign(filter_stage_id: "")
     |> assign(show_form: false)
     |> assign(form: to_form(Candidates.change_candidate(%Candidate{})))}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_user} locale={@locale}>
      <div class="p-8">
        <div class="flex justify-between items-center mb-8">
          <h1 class="text-2xl font-bold">Candidates</h1>
          <button
            phx-click="show_create_form"
            class="bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700"
          >
            + Add Candidate
          </button>
        </div>

        <div class="mb-6 flex flex-wrap gap-4 items-center">
          <form phx-change="search" class="flex-1 min-w-[200px]">
            <input
              type="text"
              name="search"
              value={@search}
              placeholder="Search by name or email..."
              class="w-full rounded-lg border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 text-sm"
            />
          </form>
          <form phx-change="filter_job" class="min-w-[180px]">
            <select
              name="job_id"
              class="rounded-lg border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 text-sm"
            >
              <option value="">All Jobs</option>
              <option :for={job <- @jobs} value={job.id} selected={job.id == @filter_job_id}>
                {job.title}
              </option>
            </select>
          </form>
          <form phx-change="filter_stage" class="min-w-[180px]">
            <select
              name="stage_id"
              class="rounded-lg border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 text-sm"
            >
              <option value="">All Stages</option>
              <option
                :for={stage <- @pipeline_stages}
                value={stage.id}
                selected={stage.id == @filter_stage_id}
              >
                {stage.name}
              </option>
            </select>
          </form>
        </div>

        <div :if={@show_form} class="mb-8 p-6 bg-white rounded-lg shadow">
          <h2 class="text-lg font-semibold mb-4">Add Candidate</h2>
          <.form for={@form} id="candidate-form" phx-submit="create_candidate">
            <.input field={@form[:name]} type="text" label="Name" />
            <.input field={@form[:email]} type="email" label="Email" />
            <.input field={@form[:phone]} type="text" label="Phone" />
            <.input field={@form[:linkedin_url]} type="text" label="LinkedIn URL" />

            <div :if={@candidate_fields != []} class="mt-4 border-t pt-4">
              <h3 class="text-sm font-medium text-gray-700 mb-3">Additional Information</h3>
              <div :for={field <- @candidate_fields} class="mb-3">
                <%= cond do %>
                  <% field.field_type == "select" -> %>
                    <label class="block text-sm font-medium text-gray-700 mb-1">{field.name}</label>
                    <select
                      name={"custom_fields[#{field.id}]"}
                      class="block w-full rounded-lg border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 text-sm"
                    >
                      <option value="">—</option>
                      <option
                        :for={opt <- field.options}
                        value={opt}
                        selected={opt == Map.get(@candidate.custom_fields || %{}, field.id)}
                      >
                        {opt}
                      </option>
                    </select>
                  <% field.field_type == "date" -> %>
                    <.input
                      name={"custom_fields[#{field.id}]"}
                      type="date"
                      label={field.name}
                      value={Map.get(@candidate.custom_fields || %{}, field.id, "")}
                    />
                  <% field.field_type == "number" -> %>
                    <.input
                      name={"custom_fields[#{field.id}]"}
                      type="number"
                      label={field.name}
                      value={Map.get(@candidate.custom_fields || %{}, field.id, "")}
                    />
                  <% field.field_type == "url" -> %>
                    <.input
                      name={"custom_fields[#{field.id}]"}
                      type="url"
                      label={field.name}
                      value={Map.get(@candidate.custom_fields || %{}, field.id, "")}
                      placeholder="https://"
                    />
                  <% true -> %>
                    <.input
                      name={"custom_fields[#{field.id}]"}
                      type="text"
                      label={field.name}
                      value={Map.get(@candidate.custom_fields || %{}, field.id, "")}
                    />
                <% end %>
              </div>
            </div>

            <div class="mt-4 flex gap-2">
              <.button type="submit">Add</.button>
              <.button type="button" phx-click="hide_create_form" class="bg-gray-500">Cancel</.button>
            </div>
          </.form>
        </div>

        <div class="bg-white rounded-lg shadow overflow-hidden">
          <table class="min-w-full divide-y divide-gray-200">
            <thead class="bg-gray-50">
              <tr>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Name
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Email
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Phone
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Applications
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Actions
                </th>
              </tr>
            </thead>
            <tbody class="bg-white divide-y divide-gray-200">
              <tr :for={candidate <- @candidates} class="hover:bg-gray-50">
                <td class="px-6 py-4 whitespace-nowrap font-medium text-gray-900">
                  <.link
                    navigate={~p"/app/candidates/#{candidate.id}"}
                    class="text-blue-600 hover:text-blue-900"
                  >
                    {candidate.name}
                  </.link>
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-gray-600">{candidate.email}</td>
                <td class="px-6 py-4 whitespace-nowrap text-gray-600">{candidate.phone || "-"}</td>
                <td class="px-6 py-4 whitespace-nowrap text-gray-600">
                  {candidate.application_count}
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-sm">
                  <button
                    phx-click="delete_candidate"
                    phx-value-candidate_id={candidate.id}
                    class="text-red-600 hover:text-red-900"
                  >
                    Delete
                  </button>
                </td>
              </tr>
            </tbody>
          </table>
          <div :if={@candidates == []} class="p-8 text-center text-gray-500">
            No candidates yet. Add your first candidate!
          </div>
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

  def handle_event("create_candidate", params, socket) do
    candidate_params = Map.get(params, "candidate", %{})
    custom_fields_values = Map.get(params, "custom_fields", %{})
    attrs = Map.put(candidate_params, "tenant_id", socket.assigns.current_tenant.id)

    required_fields =
      Customization.list_custom_fields_for(socket.assigns.current_tenant.id, "candidate")
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

      case Candidates.create_candidate(attrs) do
        {:ok, _candidate} ->
          candidates = Candidates.list_candidates(socket.assigns.current_tenant.id)

          {:noreply,
           socket
           |> assign(candidates: candidates, show_form: false)
           |> assign(form: to_form(Candidates.change_candidate(%Candidate{})))
           |> put_flash(:info, "Candidate added")}

        {:error, changeset} ->
          {:noreply, assign(socket, form: to_form(changeset))}
      end
    end
  end

  def handle_event("delete_candidate", %{"candidate_id" => candidate_id}, socket) do
    candidate = Candidates.get_candidate!(socket.assigns.current_tenant.id, candidate_id)
    :ok = Candidates.delete_candidate(candidate)
    candidates = Candidates.list_candidates(socket.assigns.current_tenant.id)
    {:noreply, assign(socket, candidates: candidates)}
  end

  def handle_event("search", %{"search" => search}, socket) do
    candidates = filter_candidates(socket.assigns, search: search)

    {:noreply,
     socket
     |> assign(search: search)
     |> assign(candidates: candidates)}
  end

  def handle_event("filter_job", %{"job_id" => job_id}, socket) do
    candidates = filter_candidates(socket.assigns, job_id: job_id)

    {:noreply,
     socket
     |> assign(filter_job_id: job_id)
     |> assign(candidates: candidates)}
  end

  def handle_event("filter_stage", %{"stage_id" => stage_id}, socket) do
    candidates = filter_candidates(socket.assigns, stage_id: stage_id)

    {:noreply,
     socket
     |> assign(filter_stage_id: stage_id)
     |> assign(candidates: candidates)}
  end

  defp filter_candidates(assigns, overrides) do
    filters = %{
      search: overrides[:search] || assigns.search,
      job_id: overrides[:job_id] || assigns.filter_job_id,
      stage_id: overrides[:stage_id] || assigns.filter_stage_id
    }

    candidates = Candidates.list_candidates(assigns.current_tenant.id, filters)

    Enum.map(candidates, fn candidate ->
      applications =
        Pipeline.list_applications_for_candidate(assigns.current_tenant.id, candidate.id)

      Map.put(candidate, :application_count, length(applications))
    end)
  end

  defp list_all_stages(tenant_id) do
    pipelines = Pipeline.list_pipelines(tenant_id)

    pipelines
    |> Enum.flat_map(fn pipeline ->
      Pipeline.list_pipeline_stages(pipeline.id)
    end)
    |> Enum.sort_by(& &1.position)
  end
end
