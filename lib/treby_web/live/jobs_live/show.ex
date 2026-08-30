defmodule TrebyWeb.JobsLive.Show do
  use TrebyWeb, :live_view

  alias Treby.{Accounts, Tenants, Jobs, Customization, Pipeline, CandidatePortal, JobViews}
  alias Treby.Notifications.Email, as: NotificationEmail

  def mount(%{"id" => id}, session, socket) do
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

    case Jobs.get_job(tenant.id, id) do
      nil ->
        {:ok, redirect(socket, to: ~p"/404")}

      job ->
        job_fields = Customization.list_custom_fields_for(tenant.id, "job")
        pipelines = Pipeline.list_pipelines(tenant.id)
        users = Accounts.list_users(tenant.id)
        stages = stages_with_counts(pipeline_id_for(job))
        Pipeline.subscribe_to_pipeline(job.id)

        {:ok,
         socket
         |> assign(current_user: user, current_tenant: tenant)
         |> assign(job: job)
         |> assign(job_fields: job_fields)
         |> assign(pipelines: pipelines)
         |> assign(users: users)
         |> assign(stages: stages)
         |> assign(pipeline_overview: stages_with_overview(pipeline_id_for(job)))
         |> assign(editing: false)
         |> assign(show_form: false)
         |> assign(manage_pipeline: false)
         |> assign(editing_stage: nil)
         |> assign(deleting_stage: nil)
         |> assign(editing_roles: nil)
         |> assign(candidate_search: "")
         |> assign(rejecting_application: nil)
         |> assign(rejection_reason: "")
         |> assign(job_view_summary: load_job_view_summary(tenant.id, job.id))
         |> refresh_workspace()
         |> assign(form: to_form(Jobs.change_job(job)))
         |> assign(stage_form: to_form(new_stage_changeset(pipeline_id_for(job))))}
    end
  end

  def handle_info({:pipeline_updated, job_id}, socket) do
    if job_id == socket.assigns.job.id do
      {:noreply, refresh_workspace(socket)}
    else
      {:noreply, socket}
    end
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_user} locale={@locale}>
      <div class="p-8">
        <div class="flex justify-between items-center mb-8">
          <div>
            <.link
              navigate={~p"/app/jobs"}
              class="text-blue-600 hover:text-blue-900 text-sm inline-flex items-center gap-1"
            >
              <.icon name="hero-arrow-left" class="w-4 h-4" /> {gettext("Back to Jobs")}
            </.link>
            <h1 class="text-2xl font-bold mt-2">{@job.title}</h1>
            <div id="job-view-summary" class="mt-2 flex items-center gap-2 text-sm">
              <%= if @job_view_summary.total_views > 0 do %>
                <span class="inline-flex items-center gap-1 px-2 py-0.5 rounded-full bg-blue-100 dark:bg-blue-900 text-blue-800 dark:text-blue-100 text-xs font-medium">
                  <.icon name="hero-eye" class="w-3 h-3" /> {@job_view_summary.total_views} views · {@job_view_summary.views_last_7_days} last 7d
                </span>
              <% else %>
                <span class="text-xs text-base-content/50">No views yet</span>
              <% end %>
            </div>
          </div>
          <div class="flex gap-2">
            <.link
              id="job-analytics-link"
              navigate={~p"/app/jobs/#{@job.id}/analytics"}
              class="bg-base-300 text-base-content px-4 py-2 rounded-lg hover:bg-base-300 inline-flex items-center gap-1"
            >
              <.icon name="hero-chart-bar" class="w-4 h-4" /> Analytics
            </.link>
            <button
              id="copy-public-link"
              phx-hook=".CopyToClipboard"
              data-url={TrebyWeb.Endpoint.url() <> ~p"/#{@current_tenant.slug}/careers/#{@job.id}"}
              class="bg-base-300 px-4 py-2 rounded-lg hover:bg-base-300 inline-flex items-center gap-1"
            >
              <.icon name="hero-link" class="w-4 h-4" /> Copy Public Link
            </button>
            <button
              phx-click="start_editing"
              class="bg-base-300 px-4 py-2 rounded-lg hover:bg-base-300 inline-flex items-center gap-1"
            >
              <.icon name="hero-pencil" class="w-4 h-4" /> Edit
            </button>
            <.link
              navigate={~p"/app/pipeline/#{@job.id}"}
              class="bg-base-300 text-base-content px-4 py-2 rounded-lg hover:bg-base-300 inline-flex items-center gap-1"
            >
              <.icon name="hero-arrow-top-right-on-square" class="w-4 h-4" /> View Pipeline
            </.link>
          </div>
        </div>

        <div :if={@editing} class="mb-8 p-6 bg-base-100 rounded-lg shadow">
          <h2 class="text-lg font-semibold mb-4">Edit Job</h2>
          <.form for={@form} id="job-edit-form" phx-submit="update_job">
            <.input field={@form[:title]} type="text" label="Title" />
            <.input field={@form[:description]} type="textarea" label="Description" />
            <.input field={@form[:salary_range]} type="text" label="Salary Range" />
            <.input field={@form[:status]} type="select" label="Status" options={["open", "closed"]} />

            <.input
              field={@form[:pipeline_id]}
              type="select"
              label="Pipeline"
              options={Enum.map(@pipelines, &{&1.name, &1.id})}
              prompt="Default pipeline"
            />

            <div :if={@job_fields != []} class="mt-4 border-t pt-4">
              <h3 class="text-sm font-medium text-base-content/80 mb-3">Custom Fields</h3>
              <div :for={field <- @job_fields} class="mb-3">
                <%= cond do %>
                  <% field.field_type == "select" -> %>
                    <.input
                      name={"custom_fields[#{field.id}]"}
                      type="select"
                      label={field.name}
                      value={Map.get(@job.custom_fields || %{}, field.id)}
                      options={field.options}
                      prompt="—"
                    />
                  <% field.field_type == "date" -> %>
                    <.input
                      name={"custom_fields[#{field.id}]"}
                      type="date"
                      label={field.name}
                      value={Map.get(@job.custom_fields || %{}, field.id, "")}
                    />
                  <% field.field_type == "number" -> %>
                    <.input
                      name={"custom_fields[#{field.id}]"}
                      type="number"
                      label={field.name}
                      value={Map.get(@job.custom_fields || %{}, field.id, "")}
                    />
                  <% field.field_type == "url" -> %>
                    <.input
                      name={"custom_fields[#{field.id}]"}
                      type="url"
                      label={field.name}
                      value={Map.get(@job.custom_fields || %{}, field.id, "")}
                      placeholder="https://"
                    />
                  <% true -> %>
                    <.input
                      name={"custom_fields[#{field.id}]"}
                      type="text"
                      label={field.name}
                      value={Map.get(@job.custom_fields || %{}, field.id, "")}
                    />
                <% end %>
              </div>
            </div>

            <div class="mt-4 flex gap-2">
              <.button type="submit">Save</.button>
              <.button type="button" phx-click="cancel_editing" class="bg-gray-500">Cancel</.button>
            </div>
          </.form>
        </div>

        <div class="grid grid-cols-3 gap-6">
          <div class="col-span-2 bg-base-100 rounded-lg shadow p-6">
            <h2 class="text-lg font-semibold mb-4">Description</h2>
            <p class="text-base-content/80 whitespace-pre-wrap">{@job.description}</p>
          </div>
          <div class="bg-base-100 rounded-lg shadow p-6">
            <h2 class="text-lg font-semibold mb-4">Details</h2>
            <dl class="space-y-4">
              <div>
                <dt class="text-sm text-base-content/50">Salary Range</dt>
                <dd class="text-base-content">{@job.salary_range || "Not specified"}</dd>
              </div>
              <div>
                <dt class="text-sm text-base-content/50">Status</dt>
                <dd>
                  <span class={"px-2 inline-flex text-xs leading-5 font-semibold rounded-full #{if @job.status == "open", do: "bg-green-100 dark:bg-green-900 text-green-800 dark:text-green-100", else: "bg-base-200 text-base-content/90"}"}>
                    {@job.status}
                  </span>
                </dd>
              </div>
              <div>
                <dt class="text-sm text-base-content/50">Created</dt>
                <dd class="text-base-content">{Calendar.strftime(@job.inserted_at, "%b %d, %Y")}</dd>
              </div>

              <div :if={@job_fields != []} class="border-t pt-4">
                <dt class="text-sm text-base-content/50 mb-2">Custom Fields</dt>
                <dl class="space-y-2">
                  <div :for={field <- @job_fields}>
                    <dt class="text-xs text-base-content/50">{field.name}</dt>
                    <dd class="text-sm text-base-content">
                      {Map.get(@job.custom_fields || %{}, field.id, "—")}
                    </dd>
                  </div>
                </dl>
              </div>
            </dl>
          </div>
        </div>

        <%!-- Candidates Section --%>
        <div class="mt-8 bg-base-100 rounded-lg shadow p-6">
          <div class="flex items-center justify-between mb-4">
            <div>
              <h2 class="text-lg font-semibold">
                Candidates
                <span :if={@total_candidates > 0} class="text-sm font-normal text-base-content/50">
                  ({@total_candidates})
                </span>
              </h2>
              <p class="text-sm text-base-content/50">Grouped by pipeline stage</p>
            </div>
            <div :if={@total_candidates > 0} class="flex items-center gap-2">
              <input
                type="search"
                id="candidate-search"
                name="candidate_search"
                value={@candidate_search}
                phx-keyup="search_candidates"
                phx-debounce="200"
                placeholder="Search candidates..."
                class="rounded-lg px-3 py-2 text-sm bg-base-200 border border-base-300 focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
            </div>
          </div>

          <div :if={@total_candidates == 0} class="text-center text-base-content/50 py-8">
            No candidates yet
          </div>

          <div
            :if={
              @total_candidates > 0 and @candidate_search != "" and
                Enum.all?(@filtered_stages, fn {_, apps} -> apps == [] end)
            }
            class="text-center text-base-content/50 py-8"
          >
            No candidates match "{@candidate_search}"
          </div>

          <div :if={@total_candidates > 0} class="flex gap-4 overflow-x-auto pb-4">
            <div
              :for={{stage, applications} <- @filtered_stages}
              id={"stage-#{stage.id}"}
              class="flex-shrink-0 w-72 bg-base-200 rounded-lg p-4"
            >
              <div class="flex items-center gap-2 mb-3">
                <div class="w-3 h-3 rounded-full" style={"background-color: #{stage.color}"}></div>
                <h3 class="font-semibold text-sm text-base-content/90">{stage.name}</h3>
                <span class="ml-auto text-sm text-base-content/50 bg-base-300 px-2 py-0.5 rounded-full">
                  {length(applications)}
                </span>
              </div>

              <div :if={applications == []} class="text-center text-base-content/40 py-6 text-xs">
                No candidates
              </div>

              <div :if={applications != []} class="space-y-3">
                <div
                  :for={application <- applications}
                  id={"job-candidate-#{application.id}"}
                  class="bg-base-100 rounded-lg p-3 shadow-sm"
                >
                  <.candidate_card_info
                    profile_link={
                      ~p"/app/candidates/#{application.candidate_id}?return_to=/app/jobs/#{@job.id}"
                    }
                    name={application.candidate.name}
                    email={application.candidate.email}
                    reviewed={application.reviewed}
                    is_duplicate={application.is_duplicate}
                    other_positions={
                      Pipeline.other_positions_text(@application_counts, application.candidate_id)
                    }
                    upcoming_interview={Map.get(@upcoming_interviews, application.id)}
                  />
                  <a
                    :if={application.resume_url}
                    href={~p"/app/applications/#{application.id}/resume"}
                    class="text-[11px] text-blue-600 hover:text-blue-900 mt-1 inline-block"
                  >
                    View Resume
                  </a>
                  <div class="mt-2 space-y-2">
                    <label
                      for={"move-select-#{application.id}"}
                      class="block text-[10px] uppercase tracking-wide text-base-content/50"
                    >
                      Move to stage
                    </label>
                    <.form
                      for={%{}}
                      id={"move-form-#{application.id}"}
                      phx-change="move_application"
                      class="flex items-center gap-1"
                    >
                      <input
                        type="hidden"
                        name="application_id"
                        value={application.id}
                        id={"move-application-id-#{application.id}"}
                      />
                      <select
                        id={"move-select-#{application.id}"}
                        name="stage_id"
                        disabled={
                          not can_manage_stage?(stage, @current_user.id) or length(@stages) <= 1
                        }
                        class="w-full rounded-lg px-2 py-1 text-xs bg-base-200 border border-base-300 disabled:opacity-50"
                      >
                        <option
                          :for={stage_option <- @stages}
                          value={stage_option.id}
                          selected={stage_option.id == application.pipeline_stage_id}
                        >
                          {stage_option.name}
                        </option>
                      </select>
                    </.form>
                    <div class="flex items-center gap-2">
                      <button
                        phx-click="toggle_review"
                        phx-value-application_id={application.id}
                        class={[
                          "flex-1 text-[11px] px-2 py-1 rounded",
                          if(application.reviewed,
                            do: "bg-green-100 text-green-800 hover:bg-green-200",
                            else: "bg-base-200 text-base-content/70 hover:bg-base-300"
                          )
                        ]}
                      >
                        {if application.reviewed, do: "Reviewed", else: "Mark reviewed"}
                      </button>
                      <button
                        :if={can_manage_stage?(stage, @current_user.id)}
                        phx-click="reject_application"
                        phx-value-application_id={application.id}
                        disabled={not @has_rejected_stage}
                        title={
                          if @has_rejected_stage,
                            do: "Reject candidate",
                            else: "No rejected stage in this pipeline"
                        }
                        class={[
                          "flex-1 text-[11px] px-2 py-1 rounded",
                          if(@has_rejected_stage,
                            do: "bg-red-50 text-red-700 hover:bg-red-100",
                            else: "bg-base-200 text-base-content/40 cursor-not-allowed"
                          )
                        ]}
                      >
                        Reject
                      </button>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>

        <%!-- Pipeline Editor Section --%>
        <div class="mt-8 bg-base-100 rounded-lg shadow p-6">
          <div class="flex items-center justify-between mb-4">
            <div>
              <h2 class="text-lg font-semibold">Pipeline</h2>
              <p class="text-sm text-base-content/50">
                {gettext("Stages for this job")}
              </p>
            </div>
            <button
              :if={@current_membership.role == "admin"}
              phx-click="toggle_manage_pipeline"
              class={[
                "px-4 py-2 rounded-lg inline-flex items-center gap-1",
                if(@manage_pipeline,
                  do: "bg-green-600 text-white hover:bg-green-700",
                  else: "bg-base-300 text-base-content hover:bg-base-300"
                )
              ]}
            >
              <.icon
                name={if @manage_pipeline, do: "hero-check", else: "hero-wrench-screwdriver"}
                class="w-4 h-4"
              />
              {if @manage_pipeline, do: gettext("Done"), else: gettext("Manage Pipeline")}
            </button>
          </div>

          <%!-- Read-only pipeline overview (default) --%>
          <div :if={not @manage_pipeline}>
            <div :if={@pipeline_overview == []} class="text-center text-base-content/50 py-6">
              {gettext("No stages in this pipeline yet")}
            </div>
            <div :if={@pipeline_overview != []} class="space-y-2">
              <div
                :for={stage <- @pipeline_overview}
                class="flex items-center gap-3 p-3 bg-base-200 rounded-lg"
              >
                <div
                  class="w-5 h-5 rounded-full flex-shrink-0"
                  style={"background-color: #{stage.color}"}
                />
                <div class="flex-1 min-w-0">
                  <div class="flex items-center gap-2">
                    <p class="font-medium text-sm text-base-content">{stage.name}</p>
                    <span class="text-xs text-base-content/50 bg-base-300 px-1.5 py-0.5 rounded-full">
                      {stage.candidate_count}
                    </span>
                    <span
                      :if={stage.stage_type}
                      class="inline-flex items-center rounded bg-base-300 px-1.5 py-0.5 text-[10px] font-medium text-base-content/70 uppercase"
                    >
                      {stage.stage_type}
                    </span>
                  </div>
                  <div
                    :if={stage.examiners != [] or stage.reviewers != [] or stage.advancers != []}
                    class="mt-1 flex flex-wrap gap-1 text-[11px]"
                  >
                    <span
                      :for={examiner <- stage.examiners}
                      class="inline-flex items-center rounded bg-blue-50 dark:bg-blue-950 px-1.5 py-0.5 text-blue-700 dark:text-blue-300"
                    >
                      <span class="font-medium mr-0.5">E</span>{examiner.user.name}
                    </span>
                    <span
                      :for={reviewer <- stage.reviewers}
                      class="inline-flex items-center rounded bg-green-50 dark:bg-green-950 px-1.5 py-0.5 text-green-700 dark:text-green-300"
                    >
                      <span class="font-medium mr-0.5">R</span>{reviewer.user.name}
                    </span>
                    <span
                      :for={advancer <- stage.advancers}
                      class="inline-flex items-center rounded bg-purple-50 dark:bg-purple-950 px-1.5 py-0.5 text-purple-700 dark:text-purple-300"
                    >
                      <span class="font-medium mr-0.5">A</span>{advancer.user.name}
                    </span>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <%!-- Pipeline editor (only while managing) --%>
          <div :if={@manage_pipeline}>
            <div class="flex justify-end mb-4">
              <button
                phx-click="show_create_form"
                class="bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700 inline-flex items-center gap-1"
              >
                <.icon name="hero-plus" class="w-4 h-4" /> {gettext("Add Stage")}
              </button>
            </div>

            <div :if={@show_form} class="mb-6 p-5 bg-base-200 rounded-lg">
              <h3 class="text-base font-semibold mb-3">
                {if @editing_stage, do: gettext("Edit Stage"), else: gettext("New Stage")}
              </h3>
              <.form
                for={@stage_form}
                id="job-stage-form"
                phx-submit="save_stage"
                class="flex gap-4 items-end flex-wrap"
              >
                <.input
                  field={@stage_form[:name]}
                  type="text"
                  label={gettext("Name")}
                  placeholder={gettext("e.g. Technical Interview")}
                />
                <.input
                  field={@stage_form[:stage_type]}
                  type="select"
                  label={gettext("Type")}
                  options={stage_type_options()}
                />
                <.input field={@stage_form[:color]} type="color" label={gettext("Color")} />

                <div :if={@stage_form[:stage_type].value == "interview"} class="w-full">
                  <.input
                    field={@stage_form[:min_examiners]}
                    type="number"
                    label={gettext("Min Examiners Required")}
                    min="1"
                  />
                  <.input
                    field={@stage_form[:scorecard_template_id]}
                    type="select"
                    label={gettext("Scorecard Template")}
                    options={scorecard_template_options(@current_tenant.id)}
                    prompt={gettext("None")}
                  />
                </div>

                <div class="flex gap-2">
                  <.button type="submit">{gettext("Save")}</.button>
                  <.button type="button" phx-click="cancel_form" class="bg-gray-500">
                    {gettext("Cancel")}
                  </.button>
                </div>
              </.form>
            </div>

            <div
              :if={@deleting_stage}
              class="mb-6 p-5 bg-base-200 rounded-lg border-l-4 border-yellow-400"
            >
              <h3 class="text-base font-semibold mb-2">{gettext("Reassign candidates")}</h3>
              <p class="text-sm text-base-content/70 mb-3">
                {gettext("%{count} candidates are in \"%{stage}\". Move them to:",
                  count: @deleting_stage.active_count,
                  stage: @deleting_stage.name
                )}
              </p>
              <.form
                for={%{}}
                id="job-reassign-form"
                phx-submit="confirm_reassign"
                class="flex gap-4 items-end"
              >
                <.input
                  name="target_stage_id"
                  type="select"
                  label={gettext("Move to")}
                  options={Enum.map(@stages, &{&1.name, &1.id})}
                  prompt={gettext("Select a stage")}
                  value=""
                />
                <div class="flex gap-2">
                  <.button type="submit">{gettext("Move & Delete")}</.button>
                  <.button type="button" phx-click="cancel_delete" class="bg-gray-500">
                    {gettext("Cancel")}
                  </.button>
                </div>
              </.form>
            </div>

            <div :if={@stages == []} class="text-center text-base-content/50 py-6">
              {gettext("No stages in this pipeline yet")}
            </div>

            <div :if={@stages != []} class="space-y-2">
              <div
                :for={{stage, idx} <- Enum.with_index(@stages)}
                class="flex items-center justify-between p-3 bg-base-200 rounded-lg"
              >
                <div class="flex items-center gap-3">
                  <div
                    class="w-5 h-5 rounded-full flex-shrink-0"
                    style={"background-color: #{stage.color}"}
                  />
                  <div>
                    <p class="font-medium text-sm text-base-content">{stage.name}</p>
                    <div class="flex flex-wrap gap-1 mt-1">
                      <span
                        :if={stage.stage_type}
                        class="inline-flex items-center rounded bg-base-300 px-1.5 py-0.5 text-[10px] font-medium text-base-content/70 uppercase"
                      >
                        {stage.stage_type}
                      </span>
                      <span
                        :if={stage.stage_type == "interview" && stage.min_examiners > 1}
                        class="inline-flex items-center rounded bg-blue-100 px-1.5 py-0.5 text-[10px] font-medium text-blue-800"
                      >
                        {gettext("%{count} examiners", count: stage.min_examiners)}
                      </span>
                      <span
                        :if={stage.examiner_count > 0}
                        class="inline-flex items-center rounded bg-blue-50 px-1.5 py-0.5 text-[10px] font-medium text-blue-700"
                      >
                        {gettext("%{count}E", count: stage.examiner_count)}
                      </span>
                      <span
                        :if={stage.reviewer_count > 0}
                        class="inline-flex items-center rounded bg-green-50 px-1.5 py-0.5 text-[10px] font-medium text-green-700"
                      >
                        {gettext("%{count}R", count: stage.reviewer_count)}
                      </span>
                      <span
                        :if={stage.advancer_count > 0}
                        class="inline-flex items-center rounded bg-purple-50 px-1.5 py-0.5 text-[10px] font-medium text-purple-700"
                      >
                        {gettext("%{count}A", count: stage.advancer_count)}
                      </span>
                    </div>
                  </div>
                </div>
                <div :if={@current_membership.role == "admin"} class="flex items-center gap-1 text-sm">
                  <button
                    :if={idx > 0}
                    phx-click="move_stage_up"
                    phx-value-stage_id={stage.id}
                    class="text-base-content/70 hover:text-base-content px-1"
                    aria-label={gettext("Move up")}
                  >
                    &uarr;
                  </button>
                  <button
                    :if={idx < length(@stages) - 1}
                    phx-click="move_stage_down"
                    phx-value-stage_id={stage.id}
                    class="text-base-content/70 hover:text-base-content px-1"
                    aria-label={gettext("Move down")}
                  >
                    &darr;
                  </button>
                  <button
                    phx-click="edit_stage"
                    phx-value-stage_id={stage.id}
                    class="text-blue-600 hover:text-blue-900 px-1"
                  >
                    {gettext("Edit")}
                  </button>
                  <button
                    :if={stage.stage_type == "interview"}
                    phx-click="show_roles"
                    phx-value-stage_id={stage.id}
                    class="text-green-600 hover:text-green-900 px-1"
                  >
                    {gettext("Roles")}
                  </button>
                  <button
                    phx-click="delete_stage"
                    phx-value-stage_id={stage.id}
                    class="text-red-600 hover:text-red-900 px-1"
                  >
                    {gettext("Delete")}
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>

        <%!-- Role Assignment Modal --%>
        <div
          :if={@manage_pipeline and @editing_roles}
          class="fixed inset-0 bg-black/50 flex items-center justify-center z-50"
          phx-click="close_roles"
        >
          <div
            class="bg-base-100 rounded-lg shadow-xl max-w-2xl w-full mx-4 max-h-[80vh] overflow-y-auto"
            phx-click=""
          >
            <div class="p-6">
              <h2 class="text-lg font-semibold mb-4">
                {gettext("Roles for")} {@editing_roles.name}
              </h2>

              <div class="mb-6">
                <h3 class="text-sm font-medium text-base-content/70 mb-2">{gettext("Examiners")}</h3>
                <div :if={@editing_roles.examiners != []} class="flex flex-wrap gap-2 mb-2">
                  <span
                    :for={examiner <- @editing_roles.examiners}
                    class="inline-flex items-center gap-1 rounded-md bg-blue-100 px-2 py-1 text-xs"
                  >
                    {examiner.user.name}
                    <button
                      phx-click="remove_examiner"
                      phx-value-stage_id={@editing_roles.id}
                      phx-value-user_id={examiner.user_id}
                      class="text-blue-600 hover:text-blue-900"
                    >
                      &times;
                    </button>
                  </span>
                </div>
                <.form
                  for={%{}}
                  id="job-add-examiner-form"
                  phx-submit="add_examiner"
                  class="flex gap-2"
                >
                  <input type="hidden" name="stage_id" value={@editing_roles.id} />
                  <.input
                    name="user_id"
                    type="select"
                    options={
                      Enum.map(available_users(@users, @editing_roles.examiners), &{&1.name, &1.id})
                    }
                    prompt={gettext("Select user...")}
                    label=""
                    value=""
                  />
                  <.button type="submit" class="bg-blue-600 text-white px-3 py-1 rounded text-sm">
                    {gettext("Add")}
                  </.button>
                </.form>
              </div>

              <div class="mb-6">
                <h3 class="text-sm font-medium text-base-content/70 mb-2">{gettext("Reviewers")}</h3>
                <div :if={@editing_roles.reviewers != []} class="flex flex-wrap gap-2 mb-2">
                  <span
                    :for={reviewer <- @editing_roles.reviewers}
                    class="inline-flex items-center gap-1 rounded-md bg-green-100 px-2 py-1 text-xs"
                  >
                    {reviewer.user.name}
                    <button
                      phx-click="remove_reviewer"
                      phx-value-stage_id={@editing_roles.id}
                      phx-value-user_id={reviewer.user_id}
                      class="text-green-600 hover:text-green-900"
                    >
                      &times;
                    </button>
                  </span>
                </div>
                <.form
                  for={%{}}
                  id="job-add-reviewer-form"
                  phx-submit="add_reviewer"
                  class="flex gap-2"
                >
                  <input type="hidden" name="stage_id" value={@editing_roles.id} />
                  <.input
                    name="user_id"
                    type="select"
                    options={
                      Enum.map(available_users(@users, @editing_roles.reviewers), &{&1.name, &1.id})
                    }
                    prompt={gettext("Select user...")}
                    label=""
                    value=""
                  />
                  <.button type="submit" class="bg-green-600 text-white px-3 py-1 rounded text-sm">
                    {gettext("Add")}
                  </.button>
                </.form>
              </div>

              <div class="mb-6">
                <h3 class="text-sm font-medium text-base-content/70 mb-2">{gettext("Advancers")}</h3>
                <div :if={@editing_roles.advancers != []} class="flex flex-wrap gap-2 mb-2">
                  <span
                    :for={advancer <- @editing_roles.advancers}
                    class="inline-flex items-center gap-1 rounded-md bg-purple-100 px-2 py-1 text-xs"
                  >
                    {advancer.user.name}
                    <button
                      phx-click="remove_advancer"
                      phx-value-stage_id={@editing_roles.id}
                      phx-value-user_id={advancer.user_id}
                      class="text-purple-600 hover:text-purple-900"
                    >
                      &times;
                    </button>
                  </span>
                </div>
                <.form
                  for={%{}}
                  id="job-add-advancer-form"
                  phx-submit="add_advancer"
                  class="flex gap-2"
                >
                  <input type="hidden" name="stage_id" value={@editing_roles.id} />
                  <.input
                    name="user_id"
                    type="select"
                    options={
                      Enum.map(available_users(@users, @editing_roles.advancers), &{&1.name, &1.id})
                    }
                    prompt={gettext("Select user...")}
                    label=""
                    value=""
                  />
                  <.button type="submit" class="bg-purple-600 text-white px-3 py-1 rounded text-sm">
                    {gettext("Add")}
                  </.button>
                </.form>
              </div>

              <div class="flex justify-end">
                <.button type="button" phx-click="close_roles">{gettext("Done")}</.button>
              </div>
            </div>
          </div>
        </div>

        <%!-- Rejection Modal --%>
        <div
          :if={@rejecting_application}
          class="fixed inset-0 bg-black/50 flex items-center justify-center z-50"
          phx-click="cancel_reject"
        >
          <div class="bg-base-100 rounded-lg shadow-xl max-w-lg w-full mx-4" phx-click="">
            <div class="p-6">
              <h2 class="text-lg font-semibold mb-2">Reject Candidate</h2>
              <p class="text-sm text-base-content/70 mb-4">
                Are you sure you want to reject {@rejecting_application.candidate.name}?
              </p>
              <textarea
                id="rejection-reason"
                class="w-full border rounded-lg p-2 text-sm mb-4"
                rows="3"
                placeholder="Reason for rejection (required)"
                required
                phx-change="update_rejection_reason"
              >{@rejection_reason}</textarea>
              <div class="flex justify-end gap-2">
                <button
                  phx-click="cancel_reject"
                  class="px-4 py-2 text-sm rounded-lg border hover:bg-base-200"
                >
                  Cancel
                </button>
                <button
                  phx-click="confirm_reject"
                  class="px-4 py-2 text-sm rounded-lg bg-red-600 text-white hover:bg-red-700"
                >
                  Reject
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>

    <script :type={Phoenix.LiveView.ColocatedHook} name=".CopyToClipboard">
      export default {
        mounted() {
          this.el.addEventListener("click", () => {
            const url = this.el.dataset.url;
            navigator.clipboard.writeText(url).then(() => {
              this.pushEvent("copy_link_success", {});
            });
          });
        }
      }
    </script>
    """
  end

  def handle_event("copy_link_success", _params, socket) do
    {:noreply, put_flash(socket, :info, "Public link copied to clipboard")}
  end

  def handle_event("start_editing", _, socket) do
    {:noreply, assign(socket, editing: true)}
  end

  def handle_event("toggle_manage_pipeline", _, socket) do
    {:noreply,
     socket
     |> assign(
       manage_pipeline: not socket.assigns.manage_pipeline,
       show_form: false,
       editing_stage: nil,
       deleting_stage: nil,
       editing_roles: nil
     )}
  end

  def handle_event(
        "move_application",
        %{"application_id" => application_id, "stage_id" => stage_id},
        socket
      ) do
    application = Pipeline.get_application!(application_id)
    user = socket.assigns.current_user
    source_stage = Enum.find(socket.assigns.stages, &(&1.id == application.pipeline_stage_id))

    if source_stage && not can_manage_stage?(source_stage, user.id) do
      {:noreply,
       put_flash(socket, :error, "Only advancers can move candidates in interview stages")}
    else
      case Pipeline.move_application(application, stage_id, actor: user) do
        {:ok, _application} ->
          {:noreply,
           socket
           |> refresh_workspace()
           |> put_flash(:info, "Candidate moved")}

        {:error, _changeset} ->
          {:noreply, put_flash(socket, :error, "Failed to move candidate")}
      end
    end
  end

  def handle_event("toggle_review", %{"application_id" => application_id}, socket) do
    application = Pipeline.get_application!(application_id)

    case Pipeline.toggle_reviewed(application) do
      {:ok, _application} ->
        {:noreply, socket |> refresh_workspace() |> put_flash(:info, "Review state updated")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to update review state")}
    end
  end

  def handle_event("search_candidates", %{"candidate_search" => search}, socket) do
    {:noreply,
     socket
     |> assign(candidate_search: search)
     |> refresh_workspace()}
  end

  def handle_event("reject_application", %{"application_id" => application_id}, socket) do
    application = Pipeline.get_application!(application_id)

    {:noreply,
     socket
     |> assign(rejecting_application: application, rejection_reason: "")}
  end

  def handle_event("cancel_reject", _, socket) do
    {:noreply, assign(socket, rejecting_application: nil, rejection_reason: "")}
  end

  def handle_event("update_rejection_reason", %{"value" => value}, socket) do
    {:noreply, assign(socket, rejection_reason: value)}
  end

  def handle_event("confirm_reject", _, socket) do
    application = socket.assigns.rejecting_application

    if String.trim(socket.assigns.rejection_reason) == "" do
      {:noreply, put_flash(socket, :error, "Rejection motivation is required")}
    else
      application = application |> Treby.Repo.preload([:candidate, :job])
      rejection_reason = socket.assigns.rejection_reason

      job = Jobs.get_job!(socket.assigns.current_tenant.id, application.job_id)
      stages = Pipeline.list_pipeline_stages_for_job(job.id)
      rejected_stage = Enum.find(stages, &(&1.stage_type == "rejected"))

      if rejected_stage do
        attrs = %{rejection_reason: rejection_reason}

        case Pipeline.move_application(application, rejected_stage.id,
               actor: socket.assigns.current_user,
               attrs: attrs
             ) do
          {:ok, _application} ->
            try do
              {:ok, conversation} =
                CandidatePortal.create_conversation(%{
                  candidate_id: application.candidate.id,
                  tenant_id: socket.assigns.current_tenant.id,
                  subject: "Application Update",
                  context: "rejection",
                  application_id: application.id
                })

              CandidatePortal.send_message(%{
                sender_id: socket.assigns.current_user.id,
                sender_type: "recruiter",
                conversation_id: conversation.id,
                body: "We've decided to move forward with other candidates.",
                message_type: "rejection",
                metadata: %{"rejection_reason" => rejection_reason}
              })

              email =
                NotificationEmail.notification_ping(
                  application.candidate,
                  socket.assigns.current_tenant,
                  conversation.id,
                  "rejection",
                  %{"job_title" => application.job.title}
                )

              Treby.Mailer.deliver(email)
            rescue
              _ -> :ok
            catch
              _ -> :ok
            end

            {:noreply,
             socket
             |> refresh_workspace()
             |> assign(rejecting_application: nil, rejection_reason: "")
             |> put_flash(:info, "Candidate rejected")}

          {:error, _changeset} ->
            {:noreply, put_flash(socket, :error, "Failed to reject candidate")}
        end
      else
        {:noreply,
         socket
         |> assign(rejecting_application: nil, rejection_reason: "")
         |> put_flash(:error, "No rejected stage found in this pipeline")}
      end
    end
  end

  def handle_event("cancel_editing", _, socket) do
    {:noreply,
     socket
     |> assign(editing: false)
     |> assign(form: to_form(Jobs.change_job(socket.assigns.job)))}
  end

  def handle_event("update_job", params, socket) do
    job_params = Map.get(params, "job", %{})
    custom_fields_values = Map.get(params, "custom_fields", %{})

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
      attrs = Map.put(job_params, "custom_fields", custom_fields_values)

      case Jobs.update_job(socket.assigns.job, attrs) do
        {:ok, job} ->
          {:noreply,
           socket
           |> assign(job: job, editing: false)
           |> assign(stages: stages_with_counts(pipeline_id_for(job)))
           |> refresh_overview()
           |> assign(form: to_form(Jobs.change_job(job)))
           |> put_flash(:info, "Job updated")}

        {:error, changeset} ->
          {:noreply,
           socket
           |> assign(form: to_form(changeset))
           |> put_flash(:error, "Please review the errors below")}
      end
    end
  end

  def handle_event("show_create_form", _, socket) do
    pipeline_id = pipeline_id_for(socket.assigns.job)
    form = to_form(new_stage_changeset(pipeline_id))
    {:noreply, assign(socket, show_form: true, editing_stage: nil, stage_form: form)}
  end

  def handle_event("cancel_form", _, socket) do
    {:noreply, assign(socket, show_form: false, editing_stage: nil)}
  end

  def handle_event(
        "save_stage",
        _params,
        %{assigns: %{current_user: %{role: role}}} = socket
      )
      when role != "admin" do
    {:noreply, put_flash(socket, :error, "Only admins can manage pipeline stages")}
  end

  def handle_event(
        "delete_stage",
        _params,
        %{assigns: %{current_user: %{role: role}}} = socket
      )
      when role != "admin" do
    {:noreply, put_flash(socket, :error, "Only admins can manage pipeline stages")}
  end

  def handle_event(
        "move_stage_up",
        _params,
        %{assigns: %{current_user: %{role: role}}} = socket
      )
      when role != "admin" do
    {:noreply, put_flash(socket, :error, "Only admins can manage pipeline stages")}
  end

  def handle_event(
        "move_stage_down",
        _params,
        %{assigns: %{current_user: %{role: role}}} = socket
      )
      when role != "admin" do
    {:noreply, put_flash(socket, :error, "Only admins can manage pipeline stages")}
  end

  def handle_event(
        event,
        _params,
        %{assigns: %{current_user: %{role: role}}} = socket
      )
      when event in [
             "add_examiner",
             "remove_examiner",
             "add_reviewer",
             "remove_reviewer",
             "add_advancer",
             "remove_advancer"
           ] and role != "admin" do
    {:noreply, put_flash(socket, :error, "Only admins can manage pipeline stages")}
  end

  def handle_event("edit_stage", %{"stage_id" => stage_id}, socket) do
    {socket, stage} = detach_and_map_stage(socket, stage_id)
    form = to_form(Pipeline.change_pipeline_stage(stage))
    {:noreply, assign(socket, show_form: true, editing_stage: stage, stage_form: form)}
  end

  def handle_event("save_stage", %{"pipeline_stage" => stage_params}, socket) do
    socket = detach_pipeline(socket)
    pipeline_id = pipeline_id_for(socket.assigns.job)
    max_position = length(socket.assigns.stages)

    attrs =
      stage_params
      |> Map.put("pipeline_id", pipeline_id)
      |> Map.put_new("position", max_position)
      |> Map.put_new("color", "#3b82f6")

    result =
      case socket.assigns.editing_stage do
        nil -> Pipeline.create_pipeline_stage(attrs, socket.assigns.current_user)
        stage -> Pipeline.update_pipeline_stage(stage, attrs, socket.assigns.current_user)
      end

    case result do
      {:ok, _stage} ->
        {:noreply,
         socket
         |> assign(
           stages: stages_with_counts(pipeline_id),
           show_form: false,
           editing_stage: nil
         )
         |> refresh_overview()
         |> put_flash(:info, "Stage saved")}

      {:error, :unauthorized} ->
        {:noreply, put_flash(socket, :error, "Only admins can manage pipeline stages")}

      {:error, changeset} ->
        {:noreply,
         socket
         |> assign(stage_form: to_form(changeset))
         |> put_flash(:error, "Please review the errors below")}
    end
  end

  def handle_event("delete_stage", %{"stage_id" => stage_id}, socket) do
    {socket, stage} = detach_and_map_stage(socket, stage_id)
    active_count = Pipeline.active_applications_count(stage.id)
    stages = socket.assigns.stages

    cond do
      stage.stage_type == "new" and
          Enum.count(stages, &(&1.stage_type == "new")) == 1 ->
        {:noreply, put_flash(socket, :error, "Cannot delete the only entry stage.")}

      active_count > 0 ->
        deleting_stage = %{id: stage.id, name: stage.name, active_count: active_count}
        {:noreply, assign(socket, deleting_stage: deleting_stage)}

      true ->
        case Pipeline.delete_pipeline_stage(stage, socket.assigns.current_user) do
          {:ok, _} ->
            stages = stages_with_counts(pipeline_id_for(socket.assigns.job))

            {:noreply,
             socket
             |> assign(stages: stages)
             |> refresh_overview()
             |> put_flash(:info, "Stage deleted")}

          {:error, :unauthorized} ->
            {:noreply, put_flash(socket, :error, "Only admins can delete pipeline stages")}
        end
    end
  end

  def handle_event("confirm_reassign", %{"target_stage_id" => target_id}, socket) do
    stage = Pipeline.get_pipeline_stage!(socket.assigns.deleting_stage.id)
    Pipeline.reassign_and_delete_stage(stage, target_id)
    stages = stages_with_counts(pipeline_id_for(socket.assigns.job))

    {:noreply,
     socket
     |> assign(stages: stages, deleting_stage: nil)
     |> refresh_overview()
     |> put_flash(:info, "Candidates reassigned and stage deleted")}
  end

  def handle_event("cancel_delete", _, socket) do
    {:noreply, assign(socket, deleting_stage: nil)}
  end

  def handle_event("move_stage_up", %{"stage_id" => stage_id}, socket) do
    {socket, stage} = detach_and_map_stage(socket, stage_id)
    stages = socket.assigns.stages
    idx = Enum.find_index(stages, &(&1.id == stage.id))

    if idx && idx > 0 do
      above = Enum.at(stages, idx - 1)
      current = Enum.at(stages, idx)

      Pipeline.update_pipeline_stage(
        above,
        %{position: current.position},
        socket.assigns.current_user
      )

      Pipeline.update_pipeline_stage(
        current,
        %{position: above.position},
        socket.assigns.current_user
      )

      stages = stages_with_counts(pipeline_id_for(socket.assigns.job))
      {:noreply, socket |> assign(stages: stages) |> refresh_overview()}
    else
      {:noreply, socket}
    end
  end

  def handle_event("move_stage_down", %{"stage_id" => stage_id}, socket) do
    {socket, stage} = detach_and_map_stage(socket, stage_id)
    stages = socket.assigns.stages
    idx = Enum.find_index(stages, &(&1.id == stage.id))

    if idx && idx < length(stages) - 1 do
      below = Enum.at(stages, idx + 1)
      current = Enum.at(stages, idx)

      Pipeline.update_pipeline_stage(
        below,
        %{position: current.position},
        socket.assigns.current_user
      )

      Pipeline.update_pipeline_stage(
        current,
        %{position: below.position},
        socket.assigns.current_user
      )

      stages = stages_with_counts(pipeline_id_for(socket.assigns.job))
      {:noreply, socket |> assign(stages: stages) |> refresh_overview()}
    else
      {:noreply, socket}
    end
  end

  def handle_event("show_roles", %{"stage_id" => stage_id}, socket) do
    {socket, stage} = detach_and_map_stage(socket, stage_id)

    examiners = Pipeline.list_examiners(stage)
    reviewers = Pipeline.list_reviewers(stage)
    advancers = Pipeline.list_advancers(stage)

    editing_roles = %{stage | examiners: examiners, reviewers: reviewers, advancers: advancers}

    {:noreply, assign(socket, editing_roles: editing_roles)}
  end

  def handle_event("close_roles", _, socket) do
    {:noreply, assign(socket, editing_roles: nil)}
  end

  def handle_event("add_examiner", %{"stage_id" => stage_id, "user_id" => user_id}, socket) do
    stage = Pipeline.get_pipeline_stage!(stage_id)
    Pipeline.assign_examiner(stage, user_id)
    editing_roles = refresh_roles(socket.assigns.editing_roles)
    {:noreply, assign(socket, editing_roles: editing_roles)}
  end

  def handle_event("remove_examiner", %{"stage_id" => stage_id, "user_id" => user_id}, socket) do
    stage = Pipeline.get_pipeline_stage!(stage_id)
    Pipeline.remove_examiner(stage, user_id)
    editing_roles = refresh_roles(socket.assigns.editing_roles)
    {:noreply, assign(socket, editing_roles: editing_roles)}
  end

  def handle_event("add_reviewer", %{"stage_id" => stage_id, "user_id" => user_id}, socket) do
    stage = Pipeline.get_pipeline_stage!(stage_id)
    Pipeline.assign_reviewer(stage, user_id)
    editing_roles = refresh_roles(socket.assigns.editing_roles)
    {:noreply, assign(socket, editing_roles: editing_roles)}
  end

  def handle_event("remove_reviewer", %{"stage_id" => stage_id, "user_id" => user_id}, socket) do
    stage = Pipeline.get_pipeline_stage!(stage_id)
    Pipeline.remove_reviewer(stage, user_id)
    editing_roles = refresh_roles(socket.assigns.editing_roles)
    {:noreply, assign(socket, editing_roles: editing_roles)}
  end

  def handle_event("add_advancer", %{"stage_id" => stage_id, "user_id" => user_id}, socket) do
    stage = Pipeline.get_pipeline_stage!(stage_id)
    Pipeline.assign_advancer(stage, user_id)
    editing_roles = refresh_roles(socket.assigns.editing_roles)
    {:noreply, assign(socket, editing_roles: editing_roles)}
  end

  def handle_event("remove_advancer", %{"stage_id" => stage_id, "user_id" => user_id}, socket) do
    stage = Pipeline.get_pipeline_stage!(stage_id)
    Pipeline.remove_advancer(stage, user_id)
    editing_roles = refresh_roles(socket.assigns.editing_roles)
    {:noreply, assign(socket, editing_roles: editing_roles)}
  end

  defp detach_pipeline(socket) do
    {:ok, updated_job, _pipeline} = Pipeline.detach_job_pipeline(socket.assigns.job)

    socket
    |> assign(job: updated_job)
    |> assign(pipelines: Pipeline.list_pipelines(socket.assigns.current_tenant.id))
    |> assign(stages: stages_with_counts(pipeline_id_for(updated_job)))
    |> refresh_overview()
  end

  defp detach_and_map_stage(socket, stale_stage_id) do
    socket = detach_pipeline(socket)
    stale = Pipeline.get_pipeline_stage!(stale_stage_id)
    fresh = find_fresh_stage(socket.assigns.stages, stale)
    {socket, fresh}
  end

  defp find_fresh_stage(stages, stale) do
    Enum.find(stages, fn s -> s.position == stale.position and s.name == stale.name end) || stale
  end

  defp pipeline_id_for(%Treby.Jobs.Job{} = job), do: Pipeline.job_effective_pipeline_id(job)

  defp stages_with_counts(pipeline_id) do
    Pipeline.list_pipeline_stages(pipeline_id)
    |> Enum.map(fn stage ->
      examiner_count = length(Pipeline.list_examiner_ids(stage))
      reviewer_count = length(Pipeline.list_reviewer_ids(stage))
      advancer_count = length(Pipeline.list_advancer_ids(stage))

      Map.merge(stage, %{
        examiner_count: examiner_count,
        reviewer_count: reviewer_count,
        advancer_count: advancer_count
      })
    end)
  end

  defp stages_with_overview(pipeline_id) do
    Pipeline.list_pipeline_stages(pipeline_id)
    |> Enum.map(fn stage ->
      Map.merge(stage, %{
        examiners: Pipeline.list_examiners(stage),
        reviewers: Pipeline.list_reviewers(stage),
        advancers: Pipeline.list_advancers(stage),
        candidate_count: Pipeline.active_applications_count(stage.id)
      })
    end)
  end

  defp refresh_overview(socket) do
    assign(socket, pipeline_overview: stages_with_overview(pipeline_id_for(socket.assigns.job)))
  end

  defp refresh_workspace(socket) do
    job = socket.assigns.job
    applications_by_stage = Pipeline.list_applications_by_stage(job.id)

    candidate_ids =
      applications_by_stage
      |> Enum.flat_map(fn {_, apps} -> Enum.map(apps, & &1.candidate_id) end)
      |> Enum.uniq()

    application_counts =
      Pipeline.candidate_application_counts(socket.assigns.current_tenant.id, candidate_ids)

    application_ids =
      applications_by_stage |> Enum.flat_map(fn {_, apps} -> Enum.map(apps, & &1.id) end)

    upcoming_interviews = load_upcoming_interviews(application_ids)

    socket
    |> assign(applications_by_stage: applications_by_stage)
    |> assign(application_counts: application_counts)
    |> assign(upcoming_interviews: upcoming_interviews)
    |> assign(
      filtered_stages: filtered_workspace(applications_by_stage, socket.assigns.candidate_search)
    )
    |> assign(total_candidates: length(application_ids))
    |> assign(
      has_rejected_stage: Enum.any?(socket.assigns.stages, &(&1.stage_type == "rejected"))
    )
  end

  defp filtered_workspace(applications_by_stage, search) do
    term = String.downcase(String.trim(search || ""))

    Enum.map(applications_by_stage, fn {stage, apps} ->
      apps =
        if term == "" do
          apps
        else
          Enum.filter(apps, fn app ->
            String.contains?(String.downcase(app.candidate.name || ""), term) or
              String.contains?(String.downcase(app.candidate.email || ""), term)
          end)
        end

      {stage, apps}
    end)
  end

  defp load_upcoming_interviews([]), do: %{}

  defp load_upcoming_interviews(application_ids) do
    import Ecto.Query

    Treby.Interviews.InterviewEvent
    |> where(
      [e],
      e.application_id in ^application_ids and e.status == "scheduled" and
        e.start_at_utc > ^DateTime.utc_now()
    )
    |> order_by([e], asc: e.start_at_utc)
    |> Treby.Repo.all()
    |> Enum.group_by(& &1.application_id)
  end

  defp can_manage_stage?(stage, user_id) do
    stage.stage_type != "interview" or Pipeline.user_is_advancer?(stage, user_id)
  end

  defp new_stage_changeset(pipeline_id) do
    %Treby.Pipeline.PipelineStage{pipeline_id: pipeline_id}
    |> Pipeline.change_pipeline_stage()
  end

  defp stage_type_options do
    [
      {"", ""},
      {"New", "new"},
      {"Interview", "interview"},
      {"Offer", "offer"},
      {"Hired", "hired"},
      {"Rejected", "rejected"}
    ]
  end

  defp scorecard_template_options(tenant_id) do
    Treby.Scorecards.list_scorecard_templates(tenant_id)
    |> Enum.map(&{&1.name, &1.id})
  end

  defp available_users(users, assigned) do
    assigned_ids = Enum.map(assigned, & &1.user_id) |> MapSet.new()
    Enum.reject(users, &MapSet.member?(assigned_ids, &1.id))
  end

  defp refresh_roles(editing_roles) do
    stage = Pipeline.get_pipeline_stage!(editing_roles.id)

    examiners = Pipeline.list_examiners(stage)
    reviewers = Pipeline.list_reviewers(stage)
    advancers = Pipeline.list_advancers(stage)

    %{stage | examiners: examiners, reviewers: reviewers, advancers: advancers}
  end

  defp load_job_view_summary(tenant_id, job_id) do
    case JobViews.get_summary(tenant_id, job_id) do
      {:ok, summary} ->
        summary

      {:error, :not_found} ->
        %{
          total_views: 0,
          unique_views: 0,
          views_last_7_days: 0,
          views_last_30_days: 0,
          views_last_90_days: 0,
          avg_daily_views: 0.0
        }
    end
  end
end
