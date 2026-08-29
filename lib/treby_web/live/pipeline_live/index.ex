defmodule TrebyWeb.PipelineLive.Index do
  use TrebyWeb, :live_view

  alias Treby.{Accounts, Tenants, Jobs, Pipeline, EmailTemplates, BulkOperations, CandidatePortal}
  alias Treby.Notifications.Email, as: NotificationEmail

  def mount(%{"job_id" => job_id}, session, socket) do
    socket = set_locale_from_session(socket, session)
    user = Accounts.get_user!(session["user_id"])
    tenant = Tenants.get_tenant!(session["tenant_id"])

    case Jobs.get_job(tenant.id, job_id) do
      nil ->
        {:ok, redirect(socket, to: ~p"/404")}

      job ->
        applications_by_stage = Pipeline.list_applications_by_stage(job_id)
        stages = Pipeline.list_pipeline_stages_for_job(job.id)

        candidate_ids =
          applications_by_stage
          |> Enum.flat_map(fn {_, apps} -> Enum.map(apps, & &1.candidate_id) end)
          |> Enum.uniq()

        application_counts =
          Pipeline.candidate_application_counts(tenant.id, candidate_ids)

        # Load upcoming interviews for this job's applications
        application_ids =
          applications_by_stage |> Enum.flat_map(fn {_, apps} -> Enum.map(apps, & &1.id) end)

        upcoming_interviews =
          if application_ids != [] do
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
          else
            []
          end

        {:ok,
         socket
         |> assign(current_user: user, current_tenant: tenant)
         |> assign(job: job)
         |> assign(applications_by_stage: applications_by_stage)
         |> assign(stages: stages)
         |> assign(application_counts: application_counts)
         |> assign(upcoming_interviews: upcoming_interviews)
         |> assign(review_filter: "all")
         |> assign(show_email_dialog: false)
         |> assign(pending_stage_move: nil)
         |> assign(email_preview: nil)
         |> assign(selected_ids: [])
         |> assign(bulk_action: nil)
         |> assign(bulk_stage_id: nil)
         |> assign(bulk_form: to_form(%{}))
         |> assign(confirm_delete: nil)
         |> assign(show_schedule_picker: false)
         |> assign(schedule_datetime: nil)
         |> assign(schedule_date: Calendar.strftime(DateTime.utc_now(), "%Y-%m-%d"))
         |> assign(schedule_time: "09:00")
         |> assign(schedule_jitter: 5)
         |> assign(rejecting_application: nil)
         |> assign(rejection_reason: "")
         |> assign(completing_interview: nil)
         |> assign(show_scorecard_form: false)
         |> assign(scorecard_event_id: nil)
         |> assign(scorecard_criteria: [])
         |> assign(scorecard_template: nil)
         |> assign(scorecard_form: to_form(%{}))}
    end
  end

  def handle_info({:email, _email}, socket) do
    {:noreply, socket}
  end

  def handle_info({:pipeline_updated, job_id}, socket) do
    applications_by_stage = Pipeline.list_applications_by_stage(job_id)

    candidate_ids =
      applications_by_stage
      |> Enum.flat_map(fn {_, apps} -> Enum.map(apps, & &1.candidate_id) end)
      |> Enum.uniq()

    application_counts =
      Pipeline.candidate_application_counts(socket.assigns.current_tenant.id, candidate_ids)

    application_ids =
      applications_by_stage |> Enum.flat_map(fn {_, apps} -> Enum.map(apps, & &1.id) end)

    upcoming_interviews =
      if application_ids != [] do
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
      else
        %{}
      end

    {:noreply,
     socket
     |> assign(applications_by_stage: applications_by_stage)
     |> assign(application_counts: application_counts)
     |> assign(upcoming_interviews: upcoming_interviews)}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_user} locale={@locale}>
      <div class="p-8">
        <div class="flex justify-between items-center mb-8">
          <div>
            <.link
              navigate={~p"/app/jobs/#{@job.id}"}
              class="text-blue-600 hover:text-blue-900 text-sm"
            >
              &larr; Back to Job
            </.link>
            <h1 class="text-2xl font-bold mt-2">{@job.title} - Pipeline</h1>
          </div>
          <div class="flex gap-2">
            <button
              phx-click="filter_review"
              value="all"
              class={[
                "px-3 py-1 text-sm rounded-lg",
                @review_filter == "all" && "bg-blue-600 text-white",
                @review_filter != "all" && "bg-base-300 text-base-content/80 hover:bg-base-300"
              ]}
            >
              All
            </button>
            <button
              phx-click="filter_review"
              value="new"
              class={[
                "px-3 py-1 text-sm rounded-lg",
                @review_filter == "new" && "bg-blue-600 text-white",
                @review_filter != "new" && "bg-base-300 text-base-content/80 hover:bg-base-300"
              ]}
            >
              New Only
            </button>
            <button
              phx-click="filter_review"
              value="rejected"
              class={[
                "px-3 py-1 text-sm rounded-lg",
                @review_filter == "rejected" && "bg-red-600 text-white",
                @review_filter != "rejected" && "bg-base-300 text-base-content/80 hover:bg-base-300"
              ]}
            >
              Rejected
            </button>
          </div>
        </div>

        <div class="flex gap-4 overflow-x-auto pb-4">
          <div
            :for={{stage, applications} <- @applications_by_stage}
            id={"stage-#{stage.id}"}
            class="flex-shrink-0 w-80 bg-base-200 rounded-lg p-4"
            data-stage-id={stage.id}
          >
            <div class="flex items-center gap-2 mb-4">
              <div class="w-3 h-3 rounded-full" style={"background-color: #{stage.color}"}></div>
              <h3 class="font-semibold text-base-content/90">{stage.name}</h3>
              <span class="ml-auto text-sm text-base-content/50 bg-base-300 px-2 py-0.5 rounded-full">
                {length(applications)}
              </span>
            </div>

            <div
              id={"stage-cards-#{stage.id}"}
              class="space-y-3 min-h-[100px]"
              phx-hook="Sortable"
              data-stage-id={stage.id}
            >
              <div
                :for={application <- applications}
                :if={
                  @review_filter == "all" or
                    (@review_filter == "new" and not application.reviewed) or
                    (@review_filter == "rejected" and application.rejection_reason != nil)
                }
                id={"application-#{application.id}"}
                class={[
                  "bg-base-100 rounded-lg p-4 shadow-sm cursor-move hover:shadow-md transition-shadow relative",
                  application.id in @selected_ids && "ring-2 ring-blue-500"
                ]}
                data-application-id={application.id}
              >
                <div class="absolute top-2 right-2">
                  <input
                    type="checkbox"
                    phx-click="toggle_application"
                    phx-value-id={application.id}
                    checked={application.id in @selected_ids}
                    class="checkbox checkbox-sm"
                  />
                </div>
                <div class="flex items-center gap-2">
                  <.link
                    navigate={~p"/app/candidates/#{application.candidate_id}"}
                    class="font-medium text-base-content hover:text-blue-600"
                  >
                    {application.candidate.name}
                  </.link>
                  <span
                    :if={not application.reviewed}
                    class="text-xs bg-red-100 text-red-800 px-1.5 py-0.5 rounded font-medium"
                  >
                    NEW
                  </span>
                  <span
                    :if={application.is_duplicate}
                    class="text-xs bg-amber-100 text-amber-800 px-1.5 py-0.5 rounded font-medium"
                  >
                    DUPLICATE APP
                  </span>
                </div>
                <p class="text-sm text-base-content/50">{application.candidate.email}</p>
                <p
                  :if={other_positions_text(@application_counts, application.candidate_id)}
                  class="mt-1 text-xs text-blue-700"
                >
                  {other_positions_text(@application_counts, application.candidate_id)}
                </p>
                <%= case Map.get(@upcoming_interviews, application.id) do %>
                  <% [next_interview | _] -> %>
                    <div class="mt-2 flex items-center gap-1 text-xs text-green-700 dark:text-green-100 bg-green-50 dark:bg-green-950 rounded px-2 py-1">
                      <.icon name="hero-video-camera" class="w-3 h-3" />
                      <span>
                        {Elixir.Calendar.strftime(next_interview.start_at_utc, "%b %d %H:%M")}
                      </span>
                    </div>
                  <% _ -> %>
                <% end %>
                <%= if stage.stage_type == "interview" do %>
                  <% state = Pipeline.current_state(application) %>
                  <%= if state.blockers != [] do %>
                    <div class="mt-2 space-y-1">
                      <%= for blocker <- state.blockers do %>
                        <div class="flex items-center gap-1 text-xs text-amber-700 dark:text-amber-300 bg-amber-50 dark:bg-amber-950 rounded px-2 py-1">
                          <.icon name="hero-exclamation-triangle" class="w-3 h-3" />
                          <span>{blocker.label}</span>
                        </div>
                      <% end %>
                    </div>
                  <% else %>
                    <%= if Pipeline.user_is_advancer?(stage, @current_user.id) do %>
                      <div class="mt-2 flex items-center gap-1 text-xs text-green-700 dark:text-green-100 bg-green-50 dark:bg-green-950 rounded px-2 py-1">
                        <.icon name="hero-check-circle" class="w-3 h-3" />
                        <span>Ready to advance</span>
                      </div>
                    <% end %>
                  <% end %>
                <% end %>
                <a
                  :if={application.resume_url}
                  href={~p"/app/applications/#{application.id}/resume"}
                  class="text-xs text-blue-600 hover:text-blue-900 mt-1 inline-block"
                >
                  View Resume
                </a>
                <div class="flex items-center gap-3 mt-1">
                  <%= if stage.stage_type == "interview" do %>
                    <% my_interview = examiner_interview_for_card(application, @current_user.id) %>
                    <% pending_interview = pending_interview_for_card(application) %>
                    <% can_complete? =
                      @current_user.role == "admin" or
                        Pipeline.user_is_advancer?(stage, @current_user.id) or
                        my_interview != nil or
                        (pending_interview != nil and
                           pending_interview.scheduled_by_id == @current_user.id) %>
                    <%= if my_interview do %>
                      <button
                        phx-click="open_scorecard"
                        phx-value-event_id={my_interview.id}
                        class="text-xs text-blue-600 hover:text-blue-900 mt-1"
                      >
                        Scorecard
                      </button>
                    <% end %>
                    <%= if pending_interview && can_complete? do %>
                      <button
                        phx-click="complete_interview"
                        phx-value-id={pending_interview.id}
                        class="text-xs text-indigo-600 hover:text-indigo-900 mt-1"
                      >
                        Mark as completed
                      </button>
                    <% end %>
                  <% end %>
                  <%= if stage.stage_type == "interview" and Pipeline.user_is_advancer?(stage, @current_user.id) do %>
                    <% ready = Pipeline.ready_to_advance?(application) %>
                    <button
                      phx-click="advance_application"
                      phx-value-id={application.id}
                      disabled={not ready}
                      class={[
                        "text-xs mt-1",
                        if(ready,
                          do: "text-green-600 hover:text-green-900",
                          else: "text-base-content/30 cursor-not-allowed"
                        )
                      ]}
                    >
                      Advance
                    </button>
                  <% end %>
                  <%= if Pipeline.user_is_advancer?(stage, @current_user.id) do %>
                    <button
                      phx-click="reject_application"
                      phx-value-id={application.id}
                      class="text-xs text-red-600 hover:text-red-900 mt-1"
                    >
                      Reject
                    </button>
                  <% end %>
                </div>
              </div>
            </div>
          </div>
        </div>

        <.empty_state
          :if={Enum.all?(@applications_by_stage, fn {_, apps} -> apps == [] end)}
          icon="hero-kanban"
          title="No applications yet"
          description="When candidates apply to this job, they'll appear here in your pipeline. Drag and drop cards between stages to move candidates forward."
        />
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
              phx-hook=".AutoResize"
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

      <%!-- Complete Interview Confirmation Dialog --%>
      <div
        :if={@completing_interview}
        class="fixed inset-0 bg-black/50 flex items-center justify-center z-50"
        phx-click="cancel_complete_interview"
      >
        <div class="bg-base-100 rounded-lg shadow-xl max-w-lg w-full mx-4" phx-click="">
          <div class="p-6">
            <h2 class="text-lg font-semibold mb-2">Mark Interview as Completed</h2>
            <p class="text-sm text-base-content/70 mb-4">
              This marks the interview as done. You can now collect scorecards before advancing the candidate.
              The candidate's stage will not change automatically.
            </p>
            <div class="flex justify-end gap-2">
              <button
                phx-click="cancel_complete_interview"
                class="px-4 py-2 text-sm rounded-lg border hover:bg-base-200"
              >
                Cancel
              </button>
              <button
                phx-click="confirm_complete_interview"
                class="px-4 py-2 text-sm rounded-lg bg-indigo-600 text-white hover:bg-indigo-700"
              >
                Mark as completed
              </button>
            </div>
          </div>
        </div>
      </div>

      <%!-- Message Confirmation Dialog --%>
      <div
        :if={@show_email_dialog}
        class="fixed inset-0 bg-black/50 flex items-center justify-center z-50"
      >
        <div class="bg-base-100 rounded-lg shadow-xl max-w-lg w-full mx-4">
          <div class="p-6">
            <h2 class="text-lg font-semibold mb-4">Send Message Notification?</h2>
            <p class="text-sm text-base-content/70 mb-4">
              <%= if Treby.Notifications.notification_preferences_enabled?(@current_tenant, "stage_change_candidate") do %>
                A stage transition message template exists. A message will be posted to the candidate's portal automatically when you move this candidate. You can preview it below or skip posting.
              <% else %>
                A stage transition message template exists. Would you like to post it?
              <% end %>
            </p>

            <div :if={@email_preview} class="p-4 bg-base-200 rounded-lg mb-4">
              <p class="text-sm text-base-content/70 mb-2">
                <strong>Subject:</strong> {@email_preview.subject}
              </p>
              <div class="text-sm text-base-content/70" phx-no-curly-interpolation>
                {@email_preview.body}
              </div>
            </div>

            <%= if @show_schedule_picker do %>
              <div class="space-y-3 p-4 bg-base-200 rounded-lg mb-4">
                <div class="flex flex-wrap gap-2">
                  <button
                    type="button"
                    phx-click="preset_schedule"
                    phx-value-label="tomorrow_9"
                    class="px-3 py-1.5 text-sm font-medium rounded-lg border border-base-300 hover:bg-blue-50 dark:hover:bg-blue-950 hover:border-blue-300 transition-colors"
                  >
                    Tomorrow 9:00
                  </button>
                  <button
                    type="button"
                    phx-click="preset_schedule"
                    phx-value-label="tomorrow_14"
                    class="px-3 py-1.5 text-sm font-medium rounded-lg border border-base-300 hover:bg-blue-50 dark:hover:bg-blue-950 hover:border-blue-300 transition-colors"
                  >
                    Tomorrow 14:00
                  </button>
                  <button
                    type="button"
                    phx-click="preset_schedule"
                    phx-value-label="next_monday"
                    class="px-3 py-1.5 text-sm font-medium rounded-lg border border-base-300 hover:bg-blue-50 dark:hover:bg-blue-950 hover:border-blue-300 transition-colors"
                  >
                    Next Monday
                  </button>
                </div>
                <div class="grid grid-cols-2 gap-3">
                  <div>
                    <label class="block text-xs font-medium text-base-content/70 mb-1">Date</label>
                    <input
                      type="date"
                      value={@schedule_date}
                      phx-change="update_schedule_date"
                      class="input w-full"
                    />
                  </div>
                  <div>
                    <label class="block text-xs font-medium text-base-content/70 mb-1">Time</label>
                    <input
                      type="time"
                      value={@schedule_time}
                      phx-change="update_schedule_time"
                      class="input w-full"
                    />
                  </div>
                </div>
                <label class="flex items-center gap-2 cursor-pointer">
                  <input
                    type="checkbox"
                    checked={@schedule_jitter > 0}
                    phx-click="toggle_schedule_jitter"
                    class="checkbox checkbox-sm"
                  />
                  <span class="text-sm text-base-content/70">
                    Add randomness (±{@schedule_jitter} min)
                  </span>
                </label>
              </div>
            <% end %>

            <div class="flex gap-2 justify-end">
              <button
                phx-click="confirm_stage_move"
                phx-value-action="cancel"
                class="px-4 py-2 text-sm text-base-content/80 bg-base-200 rounded-lg hover:bg-base-300"
              >
                Cancel
              </button>
              <button
                phx-click="confirm_stage_move"
                phx-value-action="skip"
                class="px-4 py-2 text-sm text-base-content/80 bg-base-200 rounded-lg hover:bg-base-300"
              >
                Skip Message
              </button>
              <button
                phx-click="toggle_schedule"
                class="px-4 py-2 text-sm text-blue-700 dark:text-blue-100 bg-blue-50 dark:bg-blue-950 border border-blue-200 dark:border-blue-900 rounded-lg hover:bg-blue-100"
              >
                {if @show_schedule_picker, do: "Remove Schedule", else: "Schedule"}
              </button>
              <button
                :if={@show_schedule_picker}
                phx-click="confirm_stage_move"
                phx-value-action="schedule"
                class="px-4 py-2 text-sm text-white bg-blue-600 rounded-lg hover:bg-blue-700"
              >
                Schedule & Move
              </button>
              <button
                :if={not @show_schedule_picker}
                phx-click="confirm_stage_move"
                phx-value-action="send"
                class="px-4 py-2 text-sm text-white bg-blue-600 rounded-lg hover:bg-blue-700"
              >
                Send & Move
              </button>
            </div>
          </div>
        </div>
      </div>

      <%!-- Bulk Action Bar --%>
      <div :if={@selected_ids != []} class="fixed bottom-6 left-1/2 transform -translate-x-1/2 z-50">
        <div class="bg-gray-900 text-white rounded-lg shadow-2xl p-4 flex items-center gap-4">
          <span class="text-sm">{length(@selected_ids)} selected</span>

          <.form for={@bulk_form} id="bulk-action-form" class="flex items-center gap-2">
            <select
              phx-change="bulk_select_action"
              name="bulk_action"
              class="bg-gray-800 text-white text-sm rounded px-3 py-1.5 border border-gray-700"
            >
              <option value="">Actions...</option>
              <option value="move_stage" disabled={@stages == []}>Move to Stage</option>
              <option value="mark_reviewed">Mark as Reviewed</option>
              <option value="mark_unreviewed">Mark as New</option>
              <option value="delete">Delete</option>
            </select>

            <select
              :if={@bulk_action == "move_stage" && @stages != []}
              phx-change="bulk_select_stage"
              name="bulk_stage_id"
              class="bg-gray-800 text-white text-sm rounded px-3 py-1.5 border border-gray-700"
            >
              <option value="">Select stage...</option>
              <option :for={stage <- @stages} value={stage.id}>{stage.name}</option>
            </select>
          </.form>

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
            :if={@bulk_action == "delete"}
            phx-click="confirm_delete"
            phx-value-id="bulk"
            phx-value-title="Delete candidates"
            phx-value-message={"Are you sure you want to delete #{length(@selected_ids)} applications? This action cannot be undone."}
            class="bg-red-600 text-white text-sm px-4 py-1.5 rounded hover:bg-red-700"
          >
            Delete
          </button>

          <button
            phx-click="clear_selection"
            class="text-base-content/40 hover:text-white text-sm"
          >
            ✕
          </button>
        </div>
      </div>
    </Layouts.app>
    <.scorecard_form
      show={@show_scorecard_form}
      criteria={@scorecard_criteria}
      form={@scorecard_form}
    />
    <.confirm_modal confirm_delete={@confirm_delete} on_confirm="do_bulk_execute_delete" />
    """
  end

  def handle_event(
        "move_candidate",
        %{"application_id" => application_id, "stage_id" => stage_id},
        socket
      ) do
    application = Pipeline.get_application!(application_id)
    stage = Pipeline.get_pipeline_stage!(stage_id)

    # Check advancer permission for the target stage (admins always allowed)
    is_advancer? =
      socket.assigns.current_user.role == "admin" or
        Pipeline.user_is_advancer?(stage, socket.assigns.current_user.id)

    if is_advancer? do
      # Check for email template
      email_template =
        EmailTemplates.get_email_template_for_stage(
          socket.assigns.current_tenant.id,
          stage.stage_type
        )

      if email_template do
        # Show confirmation dialog with email preview
        sample_assigns = %{
          candidate_name: application.candidate.name,
          job_title: application.job.title,
          company_name: socket.assigns.current_tenant.name,
          stage_name: stage.name,
          recruiter_name: socket.assigns.current_user.name
        }

        {preview_subject, preview_body} =
          EmailTemplates.render_email(email_template, sample_assigns)

        now = DateTime.utc_now()

        {:noreply,
         socket
         |> assign(show_email_dialog: true)
         |> assign(pending_stage_move: %{application: application, stage: stage})
         |> assign(
           email_preview: %{
             subject: preview_subject,
             body: preview_body,
             template: email_template
           }
         )
         |> assign(show_schedule_picker: false, schedule_datetime: nil)
         |> assign(schedule_date: Calendar.strftime(now, "%Y-%m-%d"), schedule_time: "09:00")
         |> assign(schedule_jitter: 5)}
      else
        # No email template, move directly
        case Pipeline.move_application(application, stage_id, actor: socket.assigns.current_user) do
          {:ok, _application} ->
            applications_by_stage = Pipeline.list_applications_by_stage(socket.assigns.job.id)
            {:noreply, assign(socket, applications_by_stage: applications_by_stage)}

          {:error, _changeset} ->
            {:noreply, put_flash(socket, :error, "Failed to move candidate")}
        end
      end
    else
      {:noreply,
       put_flash(socket, :error, "You are not authorized to move candidates to this stage")}
    end
  end

  def handle_event("confirm_stage_move", %{"action" => action}, socket) do
    case action do
      "send" -> handle_stage_move_send(socket)
      "skip" -> handle_stage_move_skip(socket)
      "schedule" -> handle_stage_move_schedule(socket)
      "cancel" -> handle_stage_move_cancel(socket)
    end
  end

  def handle_event("toggle_schedule", _params, socket) do
    now = DateTime.utc_now()

    {:noreply,
     socket
     |> assign(show_schedule_picker: !socket.assigns.show_schedule_picker)
     |> assign(schedule_datetime: nil)
     |> assign(schedule_date: Calendar.strftime(now, "%Y-%m-%d"), schedule_time: "09:00")
     |> assign(schedule_jitter: 5)}
  end

  def handle_event("preset_schedule", %{"label" => label}, socket) do
    dt =
      case label do
        "tomorrow_9" ->
          tomorrow = Date.add(Date.utc_today(), 1)
          {:ok, dt} = DateTime.new(tomorrow, ~T[09:00:00], "Etc/UTC")
          dt

        "tomorrow_14" ->
          tomorrow = Date.add(Date.utc_today(), 1)
          {:ok, dt} = DateTime.new(tomorrow, ~T[14:00:00], "Etc/UTC")
          dt

        "next_monday" ->
          today = Date.utc_today()
          days_until_monday = (8 - Date.day_of_week(today)) |> rem(7)
          days_until_monday = if days_until_monday == 0, do: 7, else: days_until_monday
          next_monday = Date.add(today, days_until_monday)
          {:ok, dt} = DateTime.new(next_monday, ~T[09:00:00], "Etc/UTC")
          dt
      end

    {:noreply,
     assign(socket,
       schedule_datetime: dt,
       schedule_date: Calendar.strftime(dt, "%Y-%m-%d"),
       schedule_time: Calendar.strftime(dt, "%H:%M")
     )}
  end

  def handle_event("update_schedule_date", %{"value" => date}, socket) do
    time = socket.assigns.schedule_time

    dt =
      with {:ok, d} <- Date.from_iso8601(date),
           {:ok, t} <- Time.from_iso8601(time),
           {:ok, dt} <- DateTime.new(d, t, "Etc/UTC") do
        dt
      else
        _ -> socket.assigns.schedule_datetime
      end

    {:noreply, assign(socket, schedule_date: date, schedule_datetime: dt)}
  end

  def handle_event("update_schedule_time", %{"value" => time}, socket) do
    date = socket.assigns.schedule_date

    dt =
      with {:ok, d} <- Date.from_iso8601(date),
           {:ok, t} <- Time.from_iso8601(time),
           {:ok, dt} <- DateTime.new(d, t, "Etc/UTC") do
        dt
      else
        _ -> socket.assigns.schedule_datetime
      end

    {:noreply, assign(socket, schedule_time: time, schedule_datetime: dt)}
  end

  def handle_event("toggle_schedule_jitter", _params, socket) do
    current = socket.assigns.schedule_jitter
    {:noreply, assign(socket, schedule_jitter: if(current > 0, do: 0, else: 5))}
  end

  def handle_event("toggle_review", %{"application_id" => application_id}, socket) do
    application = Pipeline.get_application!(application_id)

    case Pipeline.toggle_reviewed(application) do
      {:ok, _app} ->
        applications_by_stage = Pipeline.list_applications_by_stage(socket.assigns.job.id)
        {:noreply, assign(socket, applications_by_stage: applications_by_stage)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to update review status")}
    end
  end

  def handle_event("filter_review", %{"value" => filter}, socket) do
    {:noreply, assign(socket, review_filter: filter)}
  end

  def handle_event("toggle_application", %{"id" => id}, socket) do
    selected = socket.assigns.selected_ids

    selected =
      if id in selected do
        List.delete(selected, id)
      else
        [id | selected]
      end

    {:noreply, assign(socket, selected_ids: selected)}
  end

  def handle_event("bulk_select_action", %{"bulk_action" => action}, socket) do
    {:noreply, assign(socket, bulk_action: action, bulk_stage_id: nil)}
  end

  def handle_event("bulk_select_stage", %{"bulk_stage_id" => stage_id}, socket) do
    {:noreply, assign(socket, bulk_stage_id: stage_id)}
  end

  def handle_event("bulk_execute_move", _params, socket) do
    %{selected_ids: ids, bulk_stage_id: stage_id, current_tenant: tenant} = socket.assigns

    BulkOperations.bulk_move_stage(ids, stage_id, tenant.id)

    applications_by_stage = Pipeline.list_applications_by_stage(socket.assigns.job.id)

    {:noreply,
     socket
     |> assign(
       applications_by_stage: applications_by_stage,
       selected_ids: [],
       bulk_action: nil,
       bulk_stage_id: nil
     )
     |> put_flash(:info, "#{length(ids)} applications moved")}
  end

  def handle_event("bulk_execute_mark_reviewed", _params, socket) do
    %{selected_ids: ids, current_tenant: tenant} = socket.assigns

    BulkOperations.bulk_mark_reviewed(ids, tenant.id)

    applications_by_stage = Pipeline.list_applications_by_stage(socket.assigns.job.id)

    {:noreply,
     socket
     |> assign(applications_by_stage: applications_by_stage, selected_ids: [], bulk_action: nil)
     |> put_flash(:info, "#{length(ids)} applications marked as reviewed")}
  end

  def handle_event("bulk_execute_mark_unreviewed", _params, socket) do
    %{selected_ids: ids, current_tenant: tenant} = socket.assigns

    BulkOperations.bulk_mark_unreviewed(ids, tenant.id)

    applications_by_stage = Pipeline.list_applications_by_stage(socket.assigns.job.id)

    {:noreply,
     socket
     |> assign(applications_by_stage: applications_by_stage, selected_ids: [], bulk_action: nil)
     |> put_flash(:info, "#{length(ids)} applications marked as new")}
  end

  def handle_event(
        "confirm_delete",
        %{"id" => id, "title" => title, "message" => message},
        socket
      ) do
    {:noreply, assign(socket, confirm_delete: %{id: id, title: title, message: message})}
  end

  def handle_event("cancel_delete", _params, socket) do
    {:noreply, assign(socket, confirm_delete: nil)}
  end

  def handle_event("do_bulk_execute_delete", _params, socket) do
    %{selected_ids: ids, current_tenant: tenant} = socket.assigns

    {:ok, _} = BulkOperations.bulk_delete_candidates(ids, tenant.id)

    applications_by_stage = Pipeline.list_applications_by_stage(socket.assigns.job.id)

    {:noreply,
     socket
     |> assign(
       applications_by_stage: applications_by_stage,
       selected_ids: [],
       bulk_action: nil,
       confirm_delete: nil
     )
     |> put_flash(:info, "#{length(ids)} applications deleted")}
  end

  def handle_event("clear_selection", _params, socket) do
    {:noreply, assign(socket, selected_ids: [], bulk_action: nil)}
  end

  def handle_event("reject_application", %{"id" => application_id}, socket) do
    application = Pipeline.get_application!(application_id)

    {:noreply,
     socket
     |> assign(rejecting_application: application, rejection_reason: "")}
  end

  def handle_event("cancel_reject", _, socket) do
    {:noreply,
     socket
     |> assign(rejecting_application: nil, rejection_reason: "")}
  end

  def handle_event("confirm_reject", _, socket) do
    application = socket.assigns.rejecting_application

    if String.trim(socket.assigns.rejection_reason) == "" do
      {:noreply, put_flash(socket, :error, "Rejection motivation is required")}
    else
      application = application |> Treby.Repo.preload([:candidate, :job])
      rejection_reason = socket.assigns.rejection_reason

      # Find the "rejected" stage for this pipeline
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
            # Create rejection conversation and send email to candidate
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

            applications_by_stage = Pipeline.list_applications_by_stage(socket.assigns.job.id)

            {:noreply,
             socket
             |> assign(
               applications_by_stage: applications_by_stage,
               rejecting_application: nil,
               rejection_reason: ""
             )
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

  def handle_event("update_rejection_reason", %{"value" => value}, socket) do
    {:noreply, assign(socket, rejection_reason: value)}
  end

  def handle_event("complete_interview", %{"id" => interview_id}, socket) do
    interview = Treby.Repo.get!(Treby.Interviews.InterviewEvent, interview_id)

    {:noreply, assign(socket, completing_interview: interview)}
  end

  def handle_event("cancel_complete_interview", _, socket) do
    {:noreply, assign(socket, completing_interview: nil)}
  end

  def handle_event("confirm_complete_interview", _, socket) do
    interview = socket.assigns.completing_interview

    case Treby.Interviews.complete_interview(interview, socket.assigns.current_user) do
      {:ok, _interview} ->
        applications_by_stage = Pipeline.list_applications_by_stage(socket.assigns.job.id)

        {:noreply,
         socket
         |> assign(applications_by_stage: applications_by_stage)
         |> assign(completing_interview: nil)
         |> put_flash(:info, "Interview marked as completed")}

      {:error, _changeset} ->
        {:noreply,
         socket
         |> assign(completing_interview: nil)
         |> put_flash(:error, "Failed to mark interview as completed")}
    end
  end

  def handle_event("open_scorecard", %{"event_id" => event_id}, socket) do
    template = Treby.Scorecards.get_active_template(socket.assigns.current_tenant.id)

    existing_scorecard =
      Treby.Scorecards.get_scorecard_for_interview(event_id, socket.assigns.current_user.id)

    criteria = template.criteria || []

    scores = (existing_scorecard && existing_scorecard.scores) || %{}

    form_data = %{
      "recommendation" => (existing_scorecard && existing_scorecard.recommendation) || "",
      "notes" => (existing_scorecard && existing_scorecard.notes) || ""
    }

    form_data =
      Enum.reduce(criteria, form_data, fn c, acc ->
        key = c["name"]
        Map.put(acc, key, scores[key] || "")
      end)

    {:noreply,
     socket
     |> assign(show_scorecard_form: true, scorecard_event_id: event_id)
     |> assign(scorecard_template: template)
     |> assign(scorecard_criteria: criteria)
     |> assign(scorecard_form: to_form(form_data))}
  end

  def handle_event("close_scorecard", _, socket) do
    {:noreply,
     socket
     |> assign(show_scorecard_form: false, scorecard_event_id: nil)}
  end

  def handle_event("submit_scorecard", params, socket) do
    event_id = socket.assigns.scorecard_event_id
    criteria = socket.assigns.scorecard_criteria

    scores =
      criteria
      |> Enum.map(fn c -> {c["name"], Map.get(params, c["name"], "")} end)
      |> Map.new()

    attrs = %{
      "scores" => scores,
      "recommendation" => Map.get(params, "recommendation", ""),
      "notes" => Map.get(params, "notes", ""),
      "tenant_id" => socket.assigns.current_tenant.id
    }

    case Treby.Scorecards.submit_scorecard(event_id, socket.assigns.current_user.id, attrs) do
      {:ok, _scorecard} ->
        applications_by_stage = Pipeline.list_applications_by_stage(socket.assigns.job.id)

        {:noreply,
         socket
         |> assign(show_scorecard_form: false, scorecard_event_id: nil)
         |> assign(applications_by_stage: applications_by_stage)
         |> put_flash(:info, "Scorecard submitted")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to submit scorecard")}
    end
  end

  def handle_event("advance_application", %{"id" => application_id}, socket) do
    application = Pipeline.get_application!(application_id)
    application = application |> Treby.Repo.preload(:pipeline_stage)
    stage = application.pipeline_stage

    cond do
      not Pipeline.user_is_advancer?(stage, socket.assigns.current_user.id) ->
        {:noreply,
         put_flash(socket, :error, "You are not authorized to advance candidates from this stage")}

      stage.stage_type == "interview" and not Pipeline.ready_to_advance?(application) ->
        {:noreply,
         put_flash(
           socket,
           :error,
           "Mark the interview as completed and all scorecards submitted before advancing"
         )}

      true ->
        # Find the next stage in the pipeline
        job = Jobs.get_job!(socket.assigns.current_tenant.id, application.job_id)
        stages = Pipeline.list_pipeline_stages(job.pipeline_id)
        current_idx = Enum.find_index(stages, &(&1.id == stage.id))

        next_stage =
          current_idx && current_idx + 1 < length(stages) && Enum.at(stages, current_idx + 1)

        if next_stage do
          case Pipeline.move_application(application, next_stage.id,
                 actor: socket.assigns.current_user
               ) do
            {:ok, _application} ->
              applications_by_stage = Pipeline.list_applications_by_stage(socket.assigns.job.id)
              {:noreply, assign(socket, applications_by_stage: applications_by_stage)}

            {:error, _changeset} ->
              {:noreply, put_flash(socket, :error, "Failed to advance candidate")}
          end
        else
          {:noreply, put_flash(socket, :error, "No next stage found in this pipeline")}
        end
    end
  end

  defp clear_stage_move_dialog(socket) do
    assign(socket,
      show_email_dialog: false,
      pending_stage_move: nil,
      email_preview: nil,
      show_schedule_picker: false,
      schedule_datetime: nil
    )
  end

  defp handle_stage_move_send(socket) do
    pending = socket.assigns.pending_stage_move

    case EmailTemplates.send_stage_message(
           socket.assigns.email_preview.template,
           pending.application.candidate,
           pending.application,
           %{
             candidate_name: pending.application.candidate.name,
             job_title: pending.application.job.title,
             company_name: socket.assigns.current_tenant.name,
             stage_name: pending.stage.name,
             recruiter_name: socket.assigns.current_user.name,
             actor_id: socket.assigns.current_user.id
           }
         ) do
      :ok ->
        move_and_reply(socket, pending, "Candidate moved and message sent")

      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, "Failed to post message")}
    end
  end

  defp handle_stage_move_skip(socket) do
    pending = socket.assigns.pending_stage_move

    case Pipeline.move_application(pending.application, pending.stage.id,
           actor: socket.assigns.current_user
         ) do
      {:ok, _application} ->
        move_and_reply(socket, pending, "Candidate moved without email")

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to move candidate")}
    end
  end

  defp handle_stage_move_schedule(socket) do
    schedule_datetime = socket.assigns.schedule_datetime

    if is_nil(schedule_datetime) do
      {:noreply, put_flash(socket, :error, "Please select a schedule date and time")}
    else
      pending = socket.assigns.pending_stage_move
      email_preview = socket.assigns.email_preview

      EmailTemplates.send_stage_message_scheduled(
        email_preview.template,
        pending.application.candidate,
        pending.application,
        %{
          candidate_name: pending.application.candidate.name,
          job_title: pending.application.job.title,
          company_name: socket.assigns.current_tenant.name,
          stage_name: pending.stage.name,
          recruiter_name: socket.assigns.current_user.name,
          tenant_id: socket.assigns.current_tenant.id,
          actor_id: socket.assigns.current_user.id
        },
        %{
          scheduled_at: schedule_datetime,
          jitter_minutes: socket.assigns.schedule_jitter
        }
      )

      move_and_reply(socket, pending, "Candidate moved and message scheduled")
    end
  end

  defp handle_stage_move_cancel(socket) do
    {:noreply, clear_stage_move_dialog(socket)}
  end

  defp move_and_reply(socket, pending, success_message) do
    case Pipeline.move_application(pending.application, pending.stage.id, skip_notification: true) do
      {:ok, _application} ->
        applications_by_stage = Pipeline.list_applications_by_stage(socket.assigns.job.id)

        {:noreply,
         socket
         |> assign(applications_by_stage: applications_by_stage)
         |> clear_stage_move_dialog()
         |> put_flash(:info, success_message)}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to move candidate")}
    end
  end

  def other_positions_text(counts, candidate_id) do
    total = Map.get(counts, candidate_id, 1) || 1
    other = total - 1

    if other > 0 do
      label = if other == 1, do: "position", else: "positions"
      "Also in #{other} other #{label}"
    end
  end

  defp pending_interview_for_card(application) do
    import Ecto.Query

    Treby.Interviews.InterviewEvent
    |> where([e], e.application_id == ^application.id and e.status != "completed")
    |> order_by([e], asc: e.start_at_utc)
    |> limit(1)
    |> preload(:event_examiners)
    |> Treby.Repo.one()
  end

  defp examiner_interview_for_card(application, user_id) do
    import Ecto.Query

    Treby.Interviews.InterviewEvent
    |> where([e], e.application_id == ^application.id)
    |> order_by([e], asc: e.start_at_utc)
    |> preload(:event_examiners)
    |> Treby.Repo.all()
    |> Enum.find(&Enum.any?(&1.event_examiners, fn ee -> ee.user_id == user_id end))
  end
end
