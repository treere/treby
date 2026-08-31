defmodule TrebyWeb.CandidatesLive.Index do
  use TrebyWeb, :live_view

  alias Treby.{Accounts, Tenants, Candidates, Pipeline, Jobs, Customization, BulkOperations}
  alias Treby.Candidates.Candidate

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

    Candidates.auto_merge_exact_email(tenant.id, user)

    search = params["search"] || ""
    filter_job_id = params["job_id"] || ""
    filter_stage_id = params["stage_id"] || ""

    candidates =
      Candidates.list_candidates(tenant.id, %{
        search: search,
        job_id: filter_job_id,
        stage_id: filter_stage_id
      })

    candidate_fields = Customization.list_custom_fields_for(tenant.id, "candidate")
    jobs = Jobs.list_jobs(tenant.id)
    pipeline_stages = list_all_stages(tenant.id)
    duplicate_count = length(Candidates.list_suggestion_groups(tenant.id))

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
     |> assign(search: search)
     |> assign(filter_job_id: filter_job_id)
     |> assign(filter_stage_id: filter_stage_id)
     |> assign(show_form: false)
     |> assign(selected_ids: [])
     |> assign(bulk_action: nil)
     |> assign(bulk_stage_id: nil)
     |> assign(merge_modal_open: false)
     |> assign(merge_primary_id: nil)
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
          <h1 class="text-2xl font-bold">{gettext("Candidates")}</h1>
          <div class="flex items-center gap-3">
            <.link
              :if={@duplicate_count > 0}
              navigate={~p"/app/candidates/merge"}
              class="flex items-center gap-2 px-4 py-2 rounded-lg border border-amber-300 dark:border-amber-900 bg-amber-50 dark:bg-amber-950 text-amber-800 dark:text-amber-100 hover:bg-amber-100 text-sm font-medium"
            >
              <.icon name="hero-user-group" class="w-4 h-4" />{gettext("Duplicates")}<span class="bg-amber-600 text-white text-xs font-semibold rounded-full px-1.5 py-0.5">
                {@duplicate_count}
              </span>
            </.link>
            <.button phx-click="show_create_form" variant="primary">
              + {gettext("Add Candidate")}
            </.button>
          </div>
        </div>

        <div class="mb-6 flex flex-wrap gap-4 items-center">
          <form phx-change="search" phx-submit="search_submit" class="flex-1 min-w-[200px]">
            <input
              type="text"
              name="search"
              value={@search}
              placeholder={gettext("Search by name or email...")}
              class="input w-full"
            />
          </form>
          <form phx-change="filter_job" class="min-w-[180px]">
            <select
              name="job_id"
              class="select w-full"
            >
              <option value="">{gettext("All Jobs")}</option>
              <option :for={job <- @jobs} value={job.id} selected={job.id == @filter_job_id}>
                {job.title}
              </option>
            </select>
          </form>
          <form phx-change="filter_stage" class="min-w-[180px]">
            <select
              name="stage_id"
              class="select w-full"
            >
              <option value="">{gettext("All Stages")}</option>
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

        <div :if={@show_form} class="mb-8 p-6 bg-base-100 rounded-lg shadow">
          <h2 class="text-lg font-semibold mb-4">{gettext("Add Candidate")}</h2>
          <.form for={@form} id="candidate-form" phx-submit="create_candidate">
            <.input field={@form[:name]} type="text" label={gettext("Name")} />
            <.input field={@form[:email]} type="email" label={gettext("Email")} />
            <.input field={@form[:phone]} type="text" label={gettext("Phone")} />
            <.input field={@form[:linkedin_url]} type="text" label={gettext("LinkedIn URL")} />
            <.input
              field={@form[:job_id]}
              type="select"
              label={gettext("Job (optional)")}
              options={Enum.map(@jobs, &{&1.title, &1.id})}
              prompt={gettext("No job — just create profile")}
            />

            <div :if={@candidate_fields != []} class="mt-4 border-t pt-4">
              <h3 class="text-sm font-medium text-base-content/80 mb-3">
                {gettext("Additional Information")}
              </h3>
              <div :for={field <- @candidate_fields} class="mb-3">
                <%= cond do %>
                  <% field.field_type == "select" -> %>
                    <.input
                      name={"custom_fields[#{field.id}]"}
                      type="select"
                      label={field.name}
                      value={Map.get(@candidate.custom_fields || %{}, field.id)}
                      options={field.options}
                      prompt="—"
                    />
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
              <.button type="submit" variant="primary">{gettext("Add")}</.button>
              <.button type="button" phx-click="hide_create_form" variant="ghost">
                {gettext("Cancel")}
              </.button>
            </div>
          </.form>
        </div>

        <div class="bg-base-100 rounded-lg shadow overflow-hidden">
          <table class="min-w-full divide-y divide-gray-200">
            <thead class="bg-base-200">
              <tr>
                <th class="px-6 py-3 text-left text-xs font-medium text-base-content/50 uppercase tracking-wider w-10">
                  <input
                    type="checkbox"
                    phx-click="toggle_select_all"
                    checked={length(@selected_ids) == length(@candidates) and @candidates != []}
                    class="checkbox checkbox-sm"
                  />
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-base-content/50 uppercase tracking-wider">
                  {gettext("Name")}
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-base-content/50 uppercase tracking-wider">
                  {gettext("Email")}
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-base-content/50 uppercase tracking-wider">
                  {gettext("Phone")}
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-base-content/50 uppercase tracking-wider">
                  {gettext("Applications")}
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-base-content/50 uppercase tracking-wider">
                  {gettext("Actions")}
                </th>
              </tr>
            </thead>
            <tbody class="bg-base-100 divide-y divide-gray-200">
              <tr
                :for={candidate <- @candidates}
                class={[
                  "hover:bg-base-200",
                  candidate.id in @selected_ids && "bg-blue-50 dark:bg-blue-950"
                ]}
              >
                <td class="px-6 py-4 whitespace-nowrap">
                  <input
                    type="checkbox"
                    phx-click="toggle_candidate"
                    phx-value-id={candidate.id}
                    checked={candidate.id in @selected_ids}
                    class="checkbox checkbox-sm"
                  />
                </td>
                <td class="px-6 py-4 whitespace-nowrap font-medium text-base-content">
                  <.link
                    navigate={~p"/app/candidates/#{candidate.id}"}
                    class="text-blue-600 hover:text-blue-900"
                  >
                    {candidate.name}
                  </.link>
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-base-content/70">{candidate.email}</td>
                <td class="px-6 py-4 whitespace-nowrap text-base-content/70">
                  {candidate.phone || "-"}
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-base-content/70">
                  {Map.get(candidate, :application_count, 0)}
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-sm">
                  <button
                    :if={@current_membership.role == "admin"}
                    phx-click="confirm_delete"
                    phx-value-id={candidate.id}
                    phx-value-title={gettext("Delete candidate")}
                    phx-value-message={
                      gettext(
                        "Are you sure you want to delete %{name}? This action cannot be undone.",
                        name: candidate.name
                      )
                    }
                    class="text-red-600 hover:text-red-900"
                  >
                    {gettext("Delete")}
                  </button>
                </td>
              </tr>
            </tbody>
          </table>
          <.empty_state
            :if={@candidates == []}
            icon="hero-user-group"
            title={gettext("No candidates yet")}
            description={
              gettext(
                "Add candidates manually, import from a CSV file, or let them apply through your career page. Candidates will appear here once added."
              )
            }
            actions={[
              %{href: ~p"/app/candidates", label: gettext("Add a candidate")},
              %{href: ~p"/app/import", label: gettext("Import from CSV")}
            ]}
          />
        </div>

        <%!-- Bulk Action Bar --%>
        <div :if={@selected_ids != []} class="fixed bottom-6 left-1/2 transform -translate-x-1/2 z-50">
          <div class="bg-gray-900 text-white rounded-lg shadow-2xl p-4 flex items-center gap-4">
            <span class="text-sm">{length(@selected_ids)} selected</span>

            <div class="flex items-center gap-2">
              <form>
                <select
                  phx-change="bulk_select_action"
                  name="bulk_action"
                  class="bg-gray-800 text-white text-sm rounded px-3 py-1.5 border border-gray-700"
                >
                  <option value="">{gettext("Actions...")}</option>
                  <option value="move_stage">{gettext("Move to Stage")}</option>
                  <option value="mark_reviewed">{gettext("Mark as Reviewed")}</option>
                  <option value="mark_unreviewed">{gettext("Mark as New")}</option>
                  <option value="send_message">{gettext("Send Message")}</option>
                  <option value="merge">{gettext("Merge into one")}</option>
                  <option value="compare">{gettext("Compare")}</option>
                  <option value="delete">{gettext("Delete")}</option>
                </select>
              </form>

              <form>
                <select
                  :if={@bulk_action == "move_stage"}
                  phx-change="bulk_select_stage"
                  name="bulk_stage_id"
                  class="bg-gray-800 text-white text-sm rounded px-3 py-1.5 border border-gray-700"
                >
                  <option value="">{gettext("Select stage...")}</option>
                  <option :for={stage <- @pipeline_stages} value={stage.id}>{stage.name}</option>
                </select>
              </form>
            </div>

            <.button
              :if={@bulk_action == "move_stage" && @bulk_stage_id != nil}
              phx-click="bulk_execute_move"
              variant="primary"
              size="sm"
            >
              {gettext("Move")}
            </.button>
            <.button
              :if={@bulk_action == "mark_reviewed"}
              phx-click="bulk_execute_mark_reviewed"
              variant="primary"
              size="sm"
            >
              {gettext("Mark Reviewed")}
            </.button>
            <.button
              :if={@bulk_action == "mark_unreviewed"}
              phx-click="bulk_execute_mark_unreviewed"
              variant="primary"
              size="sm"
            >
              {gettext("Mark New")}
            </.button>
            <.button
              :if={@bulk_action == "merge"}
              phx-click="bulk_execute_merge"
              variant="primary"
              size="sm"
            >
              {gettext("Merge...")}
            </.button>
            <.button
              :if={@bulk_action == "compare"}
              phx-click="bulk_execute_compare"
              variant="primary"
              size="sm"
            >
              {gettext("Compare")}
            </.button>
            <.button
              :if={@bulk_action == "delete"}
              phx-click="confirm_delete"
              phx-value-id="bulk"
              phx-value-on_confirm="do_bulk_execute_delete"
              phx-value-title={gettext("Delete candidates")}
              phx-value-message={
                gettext(
                  "Are you sure you want to delete %{count} candidates? This action cannot be undone.",
                  count: length(@selected_ids)
                )
              }
              variant="danger"
              size="sm"
            >
              {gettext("Delete")}
            </.button>

            <.button
              :if={@bulk_action == "send_message"}
              phx-click="bulk_execute_send_message"
              variant="primary"
              size="sm"
            >
              {gettext("Send")}
            </.button>

            <button
              phx-click="clear_selection"
              class="text-base-content/40 hover:text-white text-sm"
            >
              ✕
            </button>
          </div>
        </div>

        <%!-- Bulk Email Composer --%>
        <div
          :if={@bulk_action == "send_message"}
          class="fixed bottom-20 left-1/2 transform -translate-x-1/2 z-50"
        >
          <div class="bg-base-100 rounded-lg shadow-2xl p-6 w-96">
            <form
              id="bulk-message-composer"
              phx-submit="bulk_email_composer_submit"
              class="contents"
            >
              <h3 class="font-semibold mb-3">Send Message to {length(@selected_ids)} candidates</h3>
              <textarea
                placeholder={gettext("Use {candidate_name} for personalization")}
                value={@bulk_email_body}
                phx-change="bulk_email_body_change"
                name="bulk_email_body"
                rows={4}
                class="textarea w-full mb-3"
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
                    class="radio radio-sm"
                  />
                  <span class="text-sm font-medium text-base-content/80">{gettext("Send now")}</span>
                </label>
                <label class="flex items-center gap-2 cursor-pointer">
                  <input
                    type="radio"
                    name="bulk_email_mode"
                    value="schedule"
                    checked={@bulk_email_mode == "schedule"}
                    phx-click="bulk_email_set_mode"
                    phx-value-mode="schedule"
                    class="radio radio-sm"
                  />
                  <span class="text-sm font-medium text-base-content/80">
                    {gettext("Schedule for later")}
                  </span>
                </label>
              </div>

              <div
                :if={@bulk_email_mode == "schedule"}
                class="space-y-3 p-3 bg-base-200 rounded-lg mb-3"
              >
                <div class="flex flex-wrap gap-2">
                  <button
                    type="button"
                    phx-click="bulk_email_preset"
                    phx-value-label="tomorrow_9"
                    class="px-3 py-1.5 text-sm font-medium rounded-lg border border-base-300 hover:bg-blue-50 dark:hover:bg-blue-950 hover:border-blue-300 transition-colors"
                  >
                    {gettext("Tomorrow 9:00")}
                  </button>
                  <button
                    type="button"
                    phx-click="bulk_email_preset"
                    phx-value-label="tomorrow_14"
                    class="px-3 py-1.5 text-sm font-medium rounded-lg border border-base-300 hover:bg-blue-50 dark:hover:bg-blue-950 hover:border-blue-300 transition-colors"
                  >
                    {gettext("Tomorrow 14:00")}
                  </button>
                  <button
                    type="button"
                    phx-click="bulk_email_preset"
                    phx-value-label="next_monday"
                    class="px-3 py-1.5 text-sm font-medium rounded-lg border border-base-300 hover:bg-blue-50 dark:hover:bg-blue-950 hover:border-blue-300 transition-colors"
                  >
                    {gettext("Next Monday")}
                  </button>
                </div>
                <div class="grid grid-cols-2 gap-3">
                  <div>
                    <label class="block text-xs font-medium text-base-content/70 mb-1">
                      {gettext("Date")}
                    </label>
                    <input
                      type="date"
                      value={@bulk_email_date}
                      phx-change="bulk_email_schedule_date_change"
                      class="input w-full"
                    />
                  </div>
                  <div>
                    <label class="block text-xs font-medium text-base-content/70 mb-1">
                      {gettext("Time")}
                    </label>
                    <input
                      type="time"
                      value={@bulk_email_time}
                      phx-change="bulk_email_schedule_time_change"
                      class="input w-full"
                    />
                  </div>
                </div>
                <label class="flex items-center gap-2 cursor-pointer">
                  <input
                    type="checkbox"
                    checked={@bulk_email_jitter > 0}
                    phx-click="bulk_email_toggle_jitter"
                    class="checkbox checkbox-sm"
                  />
                  <span class="text-sm text-base-content/70">
                    Add randomness (±{@bulk_email_jitter} min)
                  </span>
                </label>
              </div>
            </form>
          </div>
        </div>

        <%!-- Merge Primary Picker Modal --%>
        <div
          :if={@merge_modal_open}
          class="fixed inset-0 bg-black/50 flex items-center justify-center z-50"
        >
          <div class="bg-base-100 rounded-lg shadow-xl max-w-lg w-full mx-4">
            <div class="p-6">
              <h3 class="text-lg font-semibold mb-1">{gettext("Merge candidates")}</h3>
              <p class="text-sm text-base-content/50 mb-4">
                Choose the primary profile. Its data and history are kept; the other {length(
                  @selected_ids
                ) - 1} profiles are archived into it.
              </p>
              <div class="space-y-2 max-h-80 overflow-y-auto">
                <label
                  :for={candidate <- Enum.filter(@candidates, &(&1.id in @selected_ids))}
                  class="flex items-center gap-3 p-3 rounded-lg border cursor-pointer hover:bg-base-200"
                >
                  <input
                    type="radio"
                    name="merge_primary"
                    value={candidate.id}
                    phx-click="select_merge_primary"
                    phx-value-candidate_id={candidate.id}
                    checked={@merge_primary_id == candidate.id}
                    class="radio radio-sm"
                  />
                  <div class="flex-1">
                    <p class="font-medium text-base-content">{candidate.name}</p>
                    <p class="text-sm text-base-content/50">{candidate.email}</p>
                  </div>
                  <span class="text-xs text-base-content/40">
                    {Map.get(candidate, :application_count, 0)} applications
                  </span>
                </label>
              </div>
              <div class="flex justify-end gap-3 mt-6">
                <.button phx-click="cancel_merge_modal" variant="ghost" size="sm">
                  {gettext("Cancel")}
                </.button>
                <.button phx-click="do_bulk_execute_merge" variant="primary" size="sm">
                  {gettext("Merge")}
                </.button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    <.confirm_dialog
      id="confirm-candidate"
      show={@confirm_delete != nil}
      title={@confirm_delete && @confirm_delete.title}
      message={@confirm_delete && @confirm_delete.message}
      confirm_label="Delete"
      confirm_variant="danger"
      on_confirm={(@confirm_delete && Map.get(@confirm_delete, :on_confirm)) || "do_delete_candidate"}
      on_cancel="cancel_delete"
      extra_attrs={(@confirm_delete && %{id: @confirm_delete.id}) || %{}}
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
    job_id = Map.get(candidate_params, "job_id")
    candidate_params = Map.delete(candidate_params, "job_id")
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
       |> put_flash(:error, gettext("Please fill in required fields: %{fields}", fields: missing))}
    else
      attrs = Map.put(attrs, "custom_fields", custom_fields_values)

      result = Candidates.create_or_find(socket.assigns.current_tenant.id, attrs)

      case result do
        {:ok, candidate} ->
          if job_id not in [nil, ""] do
            job = Jobs.get_job(socket.assigns.current_tenant.id, job_id)

            if job do
              stage = Pipeline.list_pipeline_stages_for_job(job.id) |> List.first()

              if stage do
                Pipeline.create_application(%{
                  tenant_id: socket.assigns.current_tenant.id,
                  job_id: job.id,
                  candidate_id: candidate.id,
                  pipeline_stage_id: stage.id,
                  applied_at: DateTime.utc_now(),
                  source: "manual"
                })

                Phoenix.PubSub.broadcast(
                  Treby.PubSub,
                  "pipeline:#{job.id}",
                  {:pipeline_updated, job.id}
                )
              end
            end
          end

          candidates =
            Candidates.list_candidates(socket.assigns.current_tenant.id)
            |> Enum.map(fn c ->
              apps =
                Pipeline.list_applications_for_candidate(socket.assigns.current_tenant.id, c.id)

              Map.put(c, :application_count, length(apps))
            end)

          flash_msg =
            if job_id in [nil, ""] do
              gettext("Candidate added")
            else
              job = Jobs.get_job(socket.assigns.current_tenant.id, job_id)

              if job,
                do: gettext("Candidate added to %{title}", title: job.title),
                else: gettext("Candidate added")
            end

          {:noreply,
           socket
           |> assign(candidates: candidates, show_form: false)
           |> assign(form: to_form(Candidates.change_candidate(%Candidate{})))
           |> put_flash(:info, flash_msg)}

        {:error, changeset} ->
          {:noreply,
           socket
           |> assign(form: to_form(changeset))
           |> put_flash(:error, gettext("Please review the errors below"))}
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

  def handle_event("confirm_delete", %{"id" => candidate_id}, socket) do
    delete_candidate(socket, candidate_id)
  end

  def handle_event("cancel_delete", _params, socket) do
    {:noreply, assign(socket, confirm_delete: nil)}
  end

  def handle_event("do_delete_candidate", %{"id" => candidate_id}, socket) do
    delete_candidate(socket, candidate_id)
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

  def handle_event("bulk_execute_compare", _params, socket) do
    ids = Enum.join(socket.assigns.selected_ids, ",")
    {:noreply, push_navigate(socket, to: ~p"/app/candidates/compare?ids=#{ids}")}
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
         |> put_flash(:info, gettext("Merged candidates into %{name}", name: merged_primary.name))}

      _ ->
        {:noreply,
         socket
         |> assign(merge_modal_open: false)
         |> put_flash(
           :error,
           gettext("Merge failed. Make sure at least two candidates are selected.")
         )}
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

  def handle_event("bulk_execute_send_message", _params, socket) do
    %{
      selected_ids: ids,
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
      {:noreply, put_flash(socket, :error, gettext("Please select a schedule date and time"))}
    else
      application_ids =
        ids
        |> Enum.flat_map(fn candidate_id ->
          Pipeline.list_applications_for_candidate(tenant.id, candidate_id)
          |> Enum.map(& &1.id)
        end)

      {:ok, result} =
        BulkOperations.bulk_send_message(application_ids, body, tenant.id, schedule: schedule)

      verb = if schedule, do: "scheduled", else: "sent"

      flash_message = "#{result.sent} messages #{verb}"

      {:noreply,
       socket
       |> assign(selected_ids: [], bulk_action: nil)
       |> assign(bulk_email_body: "")
       |> assign(bulk_email_mode: "now", bulk_email_scheduled_at: nil)
       |> put_flash(:info, flash_message)}
    end
  end

  def handle_event("clear_selection", _params, socket) do
    {:noreply, assign(socket, selected_ids: [], bulk_action: nil)}
  end

  def handle_event("bulk_email_composer_submit", _params, socket) do
    {:noreply, socket}
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
    {:noreply, apply_search(socket, search)}
  end

  def handle_event("search_submit", %{"search" => search}, socket) do
    {:noreply, apply_search(socket, search)}
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

  defp apply_search(socket, search) do
    candidates = filter_candidates(socket.assigns, search: search)

    socket
    |> assign(search: search)
    |> assign(candidates: candidates)
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

  defp delete_candidate(socket, candidate_id) do
    candidate = Candidates.get_candidate!(socket.assigns.current_tenant.id, candidate_id)

    case Candidates.delete_candidate(candidate, socket.assigns.current_user) do
      {:ok, _candidate} ->
        candidates = Candidates.list_candidates(socket.assigns.current_tenant.id)

        {:noreply,
         socket
         |> assign(candidates: candidates, confirm_delete: nil)
         |> put_flash(:info, gettext("Candidate deleted"))}

      {:error, :unauthorized} ->
        {:noreply,
         socket
         |> assign(confirm_delete: nil)
         |> put_flash(:error, gettext("Only admins can delete candidates"))}

      {:error, _} ->
        {:noreply,
         socket
         |> assign(confirm_delete: nil)
         |> put_flash(:error, gettext("Failed to delete candidate"))}
    end
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
