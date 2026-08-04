defmodule TrebyWeb.CandidatesLive.Index do
  use TrebyWeb, :live_view

  alias Treby.{Accounts, Tenants, Candidates, Pipeline, Jobs, Customization, BulkOperations}
  alias Treby.Candidates.Candidate

  def mount(_params, session, socket) do
    socket = set_locale_from_session(socket, session)
    user = Accounts.get_user!(session["user_id"])
    tenant = Tenants.get_tenant!(session["tenant_id"])
    Candidates.auto_merge_exact_email(tenant.id, user)
    candidates = Candidates.list_candidates(tenant.id)
    candidate_fields = Customization.list_custom_fields_for(tenant.id, "candidate")
    jobs = Jobs.list_jobs(tenant.id)
    pipeline_stages = list_all_stages(tenant.id)
    duplicate_count = length(Candidates.list_duplicate_groups(tenant.id))

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
     |> assign(duplicate_count: duplicate_count)
     |> assign(search: "")
     |> assign(filter_job_id: "")
     |> assign(filter_stage_id: "")
     |> assign(show_form: false)
     |> assign(selected_ids: [])
     |> assign(bulk_action: nil)
     |> assign(bulk_stage_id: nil)
     |> assign(merge_modal_open: false)
     |> assign(merge_primary_id: nil)
     |> assign(bulk_email_subject: "")
     |> assign(bulk_email_body: "")
     |> assign(bulk_email_mode: "now")
     |> assign(bulk_email_scheduled_at: nil)
     |> assign(bulk_email_date: Calendar.strftime(DateTime.utc_now(), "%Y-%m-%d"))
     |> assign(bulk_email_time: "09:00")
     |> assign(bulk_email_jitter: 5)
     |> assign(bulk_summary: nil)
     |> assign(confirm_delete: nil)
     |> assign(form: to_form(Candidates.change_candidate(%Candidate{})))}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_user} locale={@locale}>
      <div class="p-8">
        <div class="flex justify-between items-center mb-8">
          <h1 class="text-2xl font-bold">Candidates</h1>
          <div class="flex items-center gap-3">
            <.link
              :if={@duplicate_count > 0}
              navigate={~p"/app/candidates/merge"}
              class="flex items-center gap-2 px-4 py-2 rounded-lg border border-amber-300 bg-amber-50 text-amber-800 hover:bg-amber-100 text-sm font-medium"
            >
              <.icon name="hero-user-group" class="w-4 h-4" /> Duplicates
              <span class="bg-amber-600 text-white text-xs font-semibold rounded-full px-1.5 py-0.5">
                {@duplicate_count}
              </span>
            </.link>
            <button
              phx-click="show_create_form"
              class="bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700"
            >
              + Add Candidate
            </button>
          </div>
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
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider w-10">
                  <input
                    type="checkbox"
                    phx-click="toggle_select_all"
                    checked={length(@selected_ids) == length(@candidates) and @candidates != []}
                    class="w-4 h-4"
                  />
                </th>
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
              <tr
                :for={candidate <- @candidates}
                class={[
                  "hover:bg-gray-50",
                  candidate.id in @selected_ids && "bg-blue-50"
                ]}
              >
                <td class="px-6 py-4 whitespace-nowrap">
                  <input
                    type="checkbox"
                    phx-click="toggle_candidate"
                    phx-value-id={candidate.id}
                    checked={candidate.id in @selected_ids}
                    class="w-4 h-4"
                  />
                </td>
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
                  {Map.get(candidate, :application_count, 0)}
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-sm">
                  <button
                    :if={@current_user.role == "admin"}
                    phx-click="confirm_delete"
                    phx-value-id={candidate.id}
                    phx-value-title="Delete candidate"
                    phx-value-message={"Are you sure you want to delete #{candidate.name}? This action cannot be undone."}
                    class="text-red-600 hover:text-red-900"
                  >
                    Delete
                  </button>
                </td>
              </tr>
            </tbody>
          </table>
          <.empty_state
            :if={@candidates == []}
            icon="hero-user-group"
            title="No candidates yet"
            description="Add candidates manually, import from a CSV file, or let them apply through your career page. Candidates will appear here once added."
            actions={[
              %{href: ~p"/app/candidates", label: "Add a candidate"},
              %{href: ~p"/app/import", label: "Import from CSV"}
            ]}
          />
        </div>

        <%!-- Bulk Action Bar --%>
        <div :if={@selected_ids != []} class="fixed bottom-6 left-1/2 transform -translate-x-1/2 z-50">
          <div class="bg-gray-900 text-white rounded-lg shadow-2xl p-4 flex items-center gap-4">
            <span class="text-sm">{length(@selected_ids)} selected</span>

            <div class="flex items-center gap-2">
              <select
                phx-change="bulk_select_action"
                name="bulk_action"
                class="bg-gray-800 text-white text-sm rounded px-3 py-1.5 border border-gray-700"
              >
                <option value="">Actions...</option>
                <option value="move_stage">Move to Stage</option>
                <option value="mark_reviewed">Mark as Reviewed</option>
                <option value="mark_unreviewed">Mark as New</option>
                <option value="send_email">Send Email</option>
                <option value="merge">Merge into one</option>
                <option value="delete">Delete</option>
              </select>

              <select
                :if={@bulk_action == "move_stage"}
                phx-change="bulk_select_stage"
                name="bulk_stage_id"
                class="bg-gray-800 text-white text-sm rounded px-3 py-1.5 border border-gray-700"
              >
                <option value="">Select stage...</option>
                <option :for={stage <- @pipeline_stages} value={stage.id}>{stage.name}</option>
              </select>
            </div>

            <button
              :if={@bulk_action == "move_stage" && @bulk_stage_id != nil}
              phx-click="bulk_execute_move"
              class="bg-blue-600 text-white text-sm px-4 py-1.5 rounded hover:bg-blue-700"
            >
              Move
            </button>
            <button
              :if={@bulk_action == "mark_reviewed"}
              phx-click="bulk_execute_mark_reviewed"
              class="bg-blue-600 text-white text-sm px-4 py-1.5 rounded hover:bg-blue-700"
            >
              Mark Reviewed
            </button>
            <button
              :if={@bulk_action == "mark_unreviewed"}
              phx-click="bulk_execute_mark_unreviewed"
              class="bg-blue-600 text-white text-sm px-4 py-1.5 rounded hover:bg-blue-700"
            >
              Mark New
            </button>
            <button
              :if={@bulk_action == "merge"}
              phx-click="bulk_execute_merge"
              class="bg-blue-600 text-white text-sm px-4 py-1.5 rounded hover:bg-blue-700"
            >
              Merge...
            </button>
            <button
              :if={@bulk_action == "delete"}
              phx-click="confirm_delete"
              phx-value-id="bulk"
              phx-value-on_confirm="do_bulk_execute_delete"
              phx-value-title="Delete candidates"
              phx-value-message={"Are you sure you want to delete #{length(@selected_ids)} candidates? This action cannot be undone."}
              class="bg-red-600 text-white text-sm px-4 py-1.5 rounded hover:bg-red-700"
            >
              Delete
            </button>

            <button
              :if={@bulk_action == "send_email"}
              phx-click="bulk_execute_send_email"
              class="bg-blue-600 text-white text-sm px-4 py-1.5 rounded hover:bg-blue-700"
            >
              Send
            </button>

            <button
              phx-click="clear_selection"
              class="text-gray-400 hover:text-white text-sm"
            >
              ✕
            </button>
          </div>
        </div>

        <%!-- Bulk Email Composer --%>
        <div
          :if={@bulk_action == "send_email"}
          class="fixed bottom-20 left-1/2 transform -translate-x-1/2 z-50"
        >
          <div class="bg-white rounded-lg shadow-2xl p-6 w-96">
            <h3 class="font-semibold mb-3">Send Email to {length(@selected_ids)} candidates</h3>
            <input
              type="text"
              placeholder="Subject"
              value={@bulk_email_subject}
              phx-change="bulk_email_subject_change"
              name="bulk_email_subject"
              class="w-full border rounded-lg px-3 py-2 text-sm mb-3"
            />
            <textarea
              placeholder="Use {candidate_name} for personalization"
              value={@bulk_email_body}
              phx-change="bulk_email_body_change"
              name="bulk_email_body"
              rows={4}
              class="w-full border rounded-lg px-3 py-2 text-sm mb-3"
            />

            <div class="flex gap-4 mb-3">
              <label class="flex items-center gap-2 cursor-pointer">
                <input
                  type="radio"
                  name="bulk_email_mode"
                  value="now"
                  checked={@bulk_email_mode == "now"}
                  phx-click="bulk_email_set_mode"
                  phx-value-mode="now"
                  class="text-blue-600"
                />
                <span class="text-sm font-medium text-gray-700">Send now</span>
              </label>
              <label class="flex items-center gap-2 cursor-pointer">
                <input
                  type="radio"
                  name="bulk_email_mode"
                  value="schedule"
                  checked={@bulk_email_mode == "schedule"}
                  phx-click="bulk_email_set_mode"
                  phx-value-mode="schedule"
                  class="text-blue-600"
                />
                <span class="text-sm font-medium text-gray-700">Schedule for later</span>
              </label>
            </div>

            <div :if={@bulk_email_mode == "schedule"} class="space-y-3 p-3 bg-gray-50 rounded-lg mb-3">
              <div class="flex flex-wrap gap-2">
                <button
                  type="button"
                  phx-click="bulk_email_preset"
                  phx-value-label="tomorrow_9"
                  class="px-3 py-1.5 text-sm font-medium rounded-lg border border-gray-300 hover:bg-blue-50 hover:border-blue-300 transition-colors"
                >
                  Tomorrow 9:00
                </button>
                <button
                  type="button"
                  phx-click="bulk_email_preset"
                  phx-value-label="tomorrow_14"
                  class="px-3 py-1.5 text-sm font-medium rounded-lg border border-gray-300 hover:bg-blue-50 hover:border-blue-300 transition-colors"
                >
                  Tomorrow 14:00
                </button>
                <button
                  type="button"
                  phx-click="bulk_email_preset"
                  phx-value-label="next_monday"
                  class="px-3 py-1.5 text-sm font-medium rounded-lg border border-gray-300 hover:bg-blue-50 hover:border-blue-300 transition-colors"
                >
                  Next Monday
                </button>
              </div>
              <div class="grid grid-cols-2 gap-3">
                <div>
                  <label class="block text-xs font-medium text-gray-600 mb-1">Date</label>
                  <input
                    type="date"
                    value={@bulk_email_date}
                    phx-change="bulk_email_schedule_date_change"
                    class="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm"
                  />
                </div>
                <div>
                  <label class="block text-xs font-medium text-gray-600 mb-1">Time</label>
                  <input
                    type="time"
                    value={@bulk_email_time}
                    phx-change="bulk_email_schedule_time_change"
                    class="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm"
                  />
                </div>
              </div>
              <label class="flex items-center gap-2 cursor-pointer">
                <input
                  type="checkbox"
                  checked={@bulk_email_jitter > 0}
                  phx-click="bulk_email_toggle_jitter"
                  class="rounded border-gray-300 text-blue-600"
                />
                <span class="text-sm text-gray-600">
                  Add randomness (±{@bulk_email_jitter} min)
                </span>
              </label>
            </div>
          </div>
        </div>

        <%!-- Merge Primary Picker Modal --%>
        <div
          :if={@merge_modal_open}
          class="fixed inset-0 bg-black/50 flex items-center justify-center z-50"
        >
          <div class="bg-white rounded-lg shadow-xl max-w-lg w-full mx-4">
            <div class="p-6">
              <h3 class="text-lg font-semibold mb-1">Merge candidates</h3>
              <p class="text-sm text-gray-500 mb-4">
                Choose the primary profile. Its data and history are kept; the other {length(
                  @selected_ids
                ) - 1} profiles are archived into it.
              </p>
              <div class="space-y-2 max-h-80 overflow-y-auto">
                <label
                  :for={candidate <- Enum.filter(@candidates, &(&1.id in @selected_ids))}
                  class="flex items-center gap-3 p-3 rounded-lg border cursor-pointer hover:bg-gray-50"
                >
                  <input
                    type="radio"
                    name="merge_primary"
                    value={candidate.id}
                    phx-click="select_merge_primary"
                    phx-value-candidate_id={candidate.id}
                    checked={@merge_primary_id == candidate.id}
                    class="w-4 h-4 text-blue-600"
                  />
                  <div class="flex-1">
                    <p class="font-medium text-gray-900">{candidate.name}</p>
                    <p class="text-sm text-gray-500">{candidate.email}</p>
                  </div>
                  <span class="text-xs text-gray-400">
                    {Map.get(candidate, :application_count, 0)} applications
                  </span>
                </label>
              </div>
              <div class="flex justify-end gap-3 mt-6">
                <button
                  phx-click="cancel_merge_modal"
                  class="px-4 py-2 rounded-lg border border-gray-300 text-sm font-medium text-gray-700 hover:bg-gray-50"
                >
                  Cancel
                </button>
                <button
                  phx-click="do_bulk_execute_merge"
                  class="px-4 py-2 rounded-lg bg-blue-600 text-white text-sm font-medium hover:bg-blue-700"
                >
                  Merge
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    <.confirm_modal
      confirm_delete={@confirm_delete}
      on_confirm={if @confirm_delete, do: @confirm_delete.on_confirm, else: "confirm_delete"}
    />
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

    attrs =
      candidate_params
      |> Map.put("tenant_id", socket.assigns.current_tenant.id)
      |> Map.put("custom_fields", custom_fields_values)

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

      result =
        if attrs["email"] in [nil, ""] do
          Candidates.create_candidate(attrs)
        else
          Candidates.find_or_create_candidate(socket.assigns.current_tenant.id, attrs)
        end

      case result do
        {:ok, _candidate} ->
          candidates = Candidates.list_candidates(socket.assigns.current_tenant.id)

          {:noreply,
           socket
           |> assign(candidates: candidates, show_form: false)
           |> assign(form: to_form(Candidates.change_candidate(%Candidate{})))
           |> put_flash(:info, "Candidate added")}

        {:error, changeset} ->
          {:noreply,
           socket
           |> assign(form: to_form(changeset))
           |> put_flash(:error, "Please review the errors below")}
      end
    end
  end

  def handle_event(
        "confirm_delete",
        %{"id" => id, "title" => title, "message" => message, "on_confirm" => on_confirm},
        socket
      ) do
    {:noreply,
     assign(socket,
       confirm_delete: %{id: id, title: title, message: message, on_confirm: on_confirm}
     )}
  end

  def handle_event(
        "confirm_delete",
        %{"id" => id, "title" => title, "message" => message},
        socket
      ) do
    {:noreply,
     assign(socket,
       confirm_delete: %{
         id: id,
         title: title,
         message: message,
         on_confirm: "do_delete_candidate"
       }
     )}
  end

  def handle_event("cancel_delete", _params, socket) do
    {:noreply, assign(socket, confirm_delete: nil)}
  end

  def handle_event("do_delete_candidate", %{"id" => candidate_id}, socket) do
    candidate = Candidates.get_candidate!(socket.assigns.current_tenant.id, candidate_id)

    case Candidates.delete_candidate(candidate, socket.assigns.current_user) do
      :ok ->
        candidates = Candidates.list_candidates(socket.assigns.current_tenant.id)

        {:noreply,
         socket
         |> assign(candidates: candidates, confirm_delete: nil)
         |> put_flash(:info, "Candidate deleted")}

      {:error, :unauthorized} ->
        {:noreply,
         socket
         |> assign(confirm_delete: nil)
         |> put_flash(:error, "Only admins can delete candidates")}

      {:error, _} ->
        {:noreply,
         socket |> assign(confirm_delete: nil) |> put_flash(:error, "Failed to delete candidate")}
    end
  end

  def handle_event("do_bulk_execute_delete", _params, socket) do
    %{selected_ids: ids, current_tenant: tenant} = socket.assigns

    application_ids =
      ids
      |> Enum.flat_map(fn candidate_id ->
        Pipeline.list_applications_for_candidate(tenant.id, candidate_id)
        |> Enum.map(& &1.id)
      end)

    {:ok, _} = BulkOperations.bulk_delete_candidates(application_ids, tenant.id)

    candidates = filter_candidates(socket.assigns, %{})

    {:noreply,
     socket
     |> assign(candidates: candidates, selected_ids: [], bulk_action: nil, confirm_delete: nil)
     |> put_flash(:info, "#{length(ids)} candidates deleted")}
  end

  def handle_event("toggle_candidate", %{"id" => id}, socket) do
    selected = socket.assigns.selected_ids

    selected =
      if id in selected do
        List.delete(selected, id)
      else
        [id | selected]
      end

    {:noreply, assign(socket, selected_ids: selected)}
  end

  def handle_event("toggle_select_all", _params, socket) do
    selected =
      if length(socket.assigns.selected_ids) == length(socket.assigns.candidates) do
        []
      else
        Enum.map(socket.assigns.candidates, & &1.id)
      end

    {:noreply, assign(socket, selected_ids: selected)}
  end

  def handle_event("bulk_select_action", %{"bulk_action" => action}, socket) do
    {:noreply, assign(socket, bulk_action: action, bulk_stage_id: nil, merge_modal_open: false)}
  end

  def handle_event("bulk_select_stage", %{"bulk_stage_id" => stage_id}, socket) do
    {:noreply, assign(socket, bulk_stage_id: stage_id)}
  end

  def handle_event("bulk_execute_merge", _params, socket) do
    primary_id = List.first(socket.assigns.selected_ids)

    {:noreply,
     socket
     |> assign(merge_modal_open: true)
     |> assign(merge_primary_id: primary_id)}
  end

  def handle_event("select_merge_primary", %{"candidate_id" => candidate_id}, socket) do
    {:noreply, assign(socket, merge_primary_id: candidate_id)}
  end

  def handle_event("cancel_merge_modal", _params, socket) do
    {:noreply, assign(socket, merge_modal_open: false)}
  end

  def handle_event("do_bulk_execute_merge", _params, socket) do
    %{selected_ids: ids, merge_primary_id: primary_id, current_tenant: tenant} = socket.assigns
    actor = socket.assigns.current_user

    candidates = Candidates.list_candidates(tenant.id)
    primary = Enum.find(candidates, &(&1.id == primary_id))
    absorbed = Enum.filter(candidates, &(&1.id in ids and &1.id != primary_id))

    case primary && Candidates.merge_candidates(primary, absorbed, actor) do
      {:ok, %{primary: merged_primary}} ->
        candidates = Candidates.list_candidates(tenant.id)

        {:noreply,
         socket
         |> assign(
           candidates: candidates,
           selected_ids: [],
           bulk_action: nil,
           merge_modal_open: false
         )
         |> put_flash(:info, "Merged candidates into #{merged_primary.name}")}

      _ ->
        {:noreply,
         socket
         |> assign(merge_modal_open: false)
         |> put_flash(:error, "Merge failed. Make sure at least two candidates are selected.")}
    end
  end

  def handle_event("bulk_execute_move", _params, socket) do
    %{selected_ids: ids, bulk_stage_id: stage_id, current_tenant: tenant} = socket.assigns

    # Get all applications for selected candidates
    application_ids =
      ids
      |> Enum.flat_map(fn candidate_id ->
        Pipeline.list_applications_for_candidate(tenant.id, candidate_id)
        |> Enum.map(& &1.id)
      end)

    BulkOperations.bulk_move_stage(application_ids, stage_id, tenant.id)

    # Re-fetch candidates
    candidates = filter_candidates(socket.assigns, %{})

    {:noreply,
     socket
     |> assign(candidates: candidates, selected_ids: [], bulk_action: nil, bulk_stage_id: nil)
     |> put_flash(:info, "#{length(ids)} candidates moved")}
  end

  def handle_event("bulk_execute_mark_reviewed", _params, socket) do
    %{selected_ids: ids, current_tenant: tenant} = socket.assigns

    application_ids =
      ids
      |> Enum.flat_map(fn candidate_id ->
        Pipeline.list_applications_for_candidate(tenant.id, candidate_id)
        |> Enum.map(& &1.id)
      end)

    BulkOperations.bulk_mark_reviewed(application_ids, tenant.id)

    candidates = filter_candidates(socket.assigns, %{})

    {:noreply,
     socket
     |> assign(candidates: candidates, selected_ids: [], bulk_action: nil)
     |> put_flash(:info, "#{length(ids)} candidates marked as reviewed")}
  end

  def handle_event("bulk_execute_mark_unreviewed", _params, socket) do
    %{selected_ids: ids, current_tenant: tenant} = socket.assigns

    application_ids =
      ids
      |> Enum.flat_map(fn candidate_id ->
        Pipeline.list_applications_for_candidate(tenant.id, candidate_id)
        |> Enum.map(& &1.id)
      end)

    BulkOperations.bulk_mark_unreviewed(application_ids, tenant.id)

    candidates = filter_candidates(socket.assigns, %{})

    {:noreply,
     socket
     |> assign(candidates: candidates, selected_ids: [], bulk_action: nil)
     |> put_flash(:info, "#{length(ids)} candidates marked as new")}
  end

  def handle_event("bulk_execute_send_email", _params, socket) do
    %{
      selected_ids: ids,
      bulk_email_subject: subject,
      bulk_email_body: body,
      bulk_email_mode: mode,
      bulk_email_scheduled_at: scheduled_at,
      bulk_email_jitter: jitter,
      current_tenant: tenant
    } = socket.assigns

    schedule =
      if mode == "schedule" && !is_nil(scheduled_at) do
        %{scheduled_at: scheduled_at, jitter_minutes: jitter}
      end

    if mode == "schedule" && is_nil(schedule) do
      {:noreply, put_flash(socket, :error, "Please select a schedule date and time")}
    else
      application_ids =
        ids
        |> Enum.flat_map(fn candidate_id ->
          Pipeline.list_applications_for_candidate(tenant.id, candidate_id)
          |> Enum.map(& &1.id)
        end)

      {:ok, result} =
        BulkOperations.bulk_send_email(application_ids, subject, body, tenant.id,
          schedule: schedule
        )

      message =
        if schedule do
          "scheduled"
        else
          "sent"
        end

      flash_message =
        if result.skipped > 0 do
          "#{result.sent} emails #{message}, #{result.skipped} skipped (no email)"
        else
          "#{result.sent} emails #{message}"
        end

      {:noreply,
       socket
       |> assign(selected_ids: [], bulk_action: nil)
       |> assign(bulk_email_subject: "", bulk_email_body: "")
       |> assign(bulk_email_mode: "now", bulk_email_scheduled_at: nil)
       |> put_flash(:info, flash_message)}
    end
  end

  def handle_event("clear_selection", _params, socket) do
    {:noreply, assign(socket, selected_ids: [], bulk_action: nil)}
  end

  def handle_event("bulk_email_subject_change", %{"bulk_email_subject" => subject}, socket) do
    {:noreply, assign(socket, bulk_email_subject: subject)}
  end

  def handle_event("bulk_email_body_change", %{"bulk_email_body" => body}, socket) do
    {:noreply, assign(socket, bulk_email_body: body)}
  end

  def handle_event("bulk_email_set_mode", %{"mode" => mode}, socket) do
    socket =
      if mode == "schedule" && is_nil(socket.assigns.bulk_email_scheduled_at) do
        dt = compute_tomorrow_9()

        assign(socket,
          bulk_email_mode: "schedule",
          bulk_email_scheduled_at: dt,
          bulk_email_date: Calendar.strftime(dt, "%Y-%m-%d"),
          bulk_email_time: "09:00"
        )
      else
        assign(socket, bulk_email_mode: mode)
      end

    {:noreply, socket}
  end

  def handle_event("bulk_email_preset", %{"label" => label}, socket) do
    dt =
      case label do
        "tomorrow_9" -> compute_tomorrow_9()
        "tomorrow_14" -> compute_tomorrow_14()
        "next_monday" -> compute_next_monday_9()
      end

    {:noreply,
     assign(socket,
       bulk_email_mode: "schedule",
       bulk_email_scheduled_at: dt,
       bulk_email_date: Calendar.strftime(dt, "%Y-%m-%d"),
       bulk_email_time: Calendar.strftime(dt, "%H:%M")
     )}
  end

  def handle_event("bulk_email_schedule_date_change", %{"value" => date}, socket) do
    dt = build_schedule_datetime(date, socket.assigns.bulk_email_time)
    {:noreply, assign(socket, bulk_email_date: date, bulk_email_scheduled_at: dt)}
  end

  def handle_event("bulk_email_schedule_time_change", %{"value" => time}, socket) do
    dt = build_schedule_datetime(socket.assigns.bulk_email_date, time)
    {:noreply, assign(socket, bulk_email_time: time, bulk_email_scheduled_at: dt)}
  end

  def handle_event("bulk_email_toggle_jitter", _params, socket) do
    current = socket.assigns.bulk_email_jitter
    {:noreply, assign(socket, bulk_email_jitter: if(current > 0, do: 0, else: 5))}
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

  defp compute_tomorrow_9 do
    tomorrow = Date.add(Date.utc_today(), 1)
    {:ok, dt} = DateTime.new(tomorrow, ~T[09:00:00], "Etc/UTC")
    dt
  end

  defp compute_tomorrow_14 do
    tomorrow = Date.add(Date.utc_today(), 1)
    {:ok, dt} = DateTime.new(tomorrow, ~T[14:00:00], "Etc/UTC")
    dt
  end

  defp compute_next_monday_9 do
    today = Date.utc_today()
    days_until_monday = (8 - Date.day_of_week(today)) |> rem(7)
    days_until_monday = if days_until_monday == 0, do: 7, else: days_until_monday
    next_monday = Date.add(today, days_until_monday)
    {:ok, dt} = DateTime.new(next_monday, ~T[09:00:00], "Etc/UTC")
    dt
  end

  defp build_schedule_datetime(date_str, time_str) do
    with {:ok, date} <- Date.from_iso8601(date_str),
         {:ok, time} <- Time.from_iso8601(time_str),
         {:ok, dt} <- DateTime.new(date, time, "Etc/UTC") do
      dt
    else
      _ -> nil
    end
  end
end
