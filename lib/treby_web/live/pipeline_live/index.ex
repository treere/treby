defmodule TrebyWeb.PipelineLive.Index do
  use TrebyWeb, :live_view

  alias Treby.{Accounts, Tenants, Jobs, Pipeline, EmailTemplates, BulkOperations}

  def mount(%{"job_id" => job_id}, session, socket) do
    socket = set_locale_from_session(socket, session)
    user = Accounts.get_user!(session["user_id"])
    tenant = Tenants.get_tenant!(session["tenant_id"])
    job = Jobs.get_job!(tenant.id, job_id)
    applications_by_stage = Pipeline.list_applications_by_stage(job_id)
    stages = Pipeline.list_pipeline_stages(tenant.id)

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
     |> assign(upcoming_interviews: upcoming_interviews)
     |> assign(review_filter: "all")
     |> assign(show_email_dialog: false)
     |> assign(pending_stage_move: nil)
     |> assign(email_preview: nil)
     |> assign(selected_ids: [])
     |> assign(bulk_action: nil)
     |> assign(bulk_stage_id: nil)
     |> assign(confirm_delete: nil)}
  end

  def handle_info({:pipeline_updated, job_id}, socket) do
    applications_by_stage = Pipeline.list_applications_by_stage(job_id)

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
                @review_filter != "all" && "bg-gray-200 text-gray-700 hover:bg-gray-300"
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
                @review_filter != "new" && "bg-gray-200 text-gray-700 hover:bg-gray-300"
              ]}
            >
              New Only
            </button>
          </div>
        </div>

        <div class="flex gap-4 overflow-x-auto pb-4">
          <div
            :for={{stage, applications} <- @applications_by_stage}
            id={"stage-#{stage.id}"}
            class="flex-shrink-0 w-80 bg-gray-100 rounded-lg p-4"
            data-stage-id={stage.id}
          >
            <div class="flex items-center gap-2 mb-4">
              <div class="w-3 h-3 rounded-full" style={"background-color: #{stage.color}"}></div>
              <h3 class="font-semibold text-gray-800">{stage.name}</h3>
              <span class="ml-auto text-sm text-gray-500 bg-gray-200 px-2 py-0.5 rounded-full">
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
                :if={@review_filter == "all" or not application.reviewed}
                id={"application-#{application.id}"}
                class={[
                  "bg-white rounded-lg p-4 shadow-sm cursor-move hover:shadow-md transition-shadow relative",
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
                    class="w-4 h-4"
                  />
                </div>
                <div class="flex items-center gap-2">
                  <p class="font-medium text-gray-900">{application.candidate.name}</p>
                  <span
                    :if={not application.reviewed}
                    class="text-xs bg-red-100 text-red-800 px-1.5 py-0.5 rounded font-medium"
                  >
                    NEW
                  </span>
                </div>
                <p class="text-sm text-gray-500">{application.candidate.email}</p>
                <%= case Map.get(@upcoming_interviews, application.id) do %>
                  <% [next_interview | _] -> %>
                    <div class="mt-2 flex items-center gap-1 text-xs text-green-700 bg-green-50 rounded px-2 py-1">
                      <.icon name="hero-video-camera" class="w-3 h-3" />
                      <span>
                        {Elixir.Calendar.strftime(next_interview.start_at_utc, "%b %d %H:%M")}
                      </span>
                    </div>
                  <% _ -> %>
                <% end %>
                <a
                  :if={application.resume_url}
                  href={~p"/app/applications/#{application.id}/resume"}
                  class="text-xs text-blue-600 hover:text-blue-900 mt-1 inline-block"
                >
                  View Resume
                </a>
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

      <%!-- Email Confirmation Dialog --%>
      <div
        :if={@show_email_dialog}
        class="fixed inset-0 bg-black/50 flex items-center justify-center z-50"
      >
        <div class="bg-white rounded-lg shadow-xl max-w-lg w-full mx-4">
          <div class="p-6">
            <h2 class="text-lg font-semibold mb-4">Send Email Notification?</h2>
            <p class="text-sm text-gray-600 mb-4">
              A stage transition email template exists. Would you like to send it?
            </p>

            <div :if={@email_preview} class="p-4 bg-gray-50 rounded-lg mb-4">
              <p class="text-sm text-gray-600 mb-2">
                <strong>Subject:</strong> {@email_preview.subject}
              </p>
              <div class="text-sm text-gray-600" phx-no-curly-interpolation>
                {@email_preview.body}
              </div>
            </div>

            <div class="flex gap-2 justify-end">
              <button
                phx-click="confirm_stage_move"
                phx-value-action="cancel"
                class="px-4 py-2 text-sm text-gray-700 bg-gray-100 rounded-lg hover:bg-gray-200"
              >
                Cancel
              </button>
              <button
                phx-click="confirm_stage_move"
                phx-value-action="skip"
                class="px-4 py-2 text-sm text-gray-700 bg-gray-100 rounded-lg hover:bg-gray-200"
              >
                Skip Email
              </button>
              <button
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
              <option value="delete">Delete</option>
            </select>

            <select
              :if={@bulk_action == "move_stage"}
              phx-change="bulk_select_stage"
              name="bulk_stage_id"
              class="bg-gray-800 text-white text-sm rounded px-3 py-1.5 border border-gray-700"
            >
              <option value="">Select stage...</option>
              <option :for={stage <- @stages} value={stage.id}>{stage.name}</option>
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
            class="text-gray-400 hover:text-white text-sm"
          >
            ✕
          </button>
        </div>
      </div>
    </Layouts.app>
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

      {:noreply,
       socket
       |> assign(show_email_dialog: true)
       |> assign(pending_stage_move: %{application: application, stage: stage})
       |> assign(
         email_preview: %{subject: preview_subject, body: preview_body, template: email_template}
       )}
    else
      # No email template, move directly
      case Pipeline.move_application(application, stage_id) do
        {:ok, _application} ->
          applications_by_stage = Pipeline.list_applications_by_stage(socket.assigns.job.id)
          {:noreply, assign(socket, applications_by_stage: applications_by_stage)}

        {:error, _changeset} ->
          {:noreply, put_flash(socket, :error, "Failed to move candidate")}
      end
    end
  end

  def handle_event("confirm_stage_move", %{"action" => action}, socket) do
    pending = socket.assigns.pending_stage_move

    case action do
      "send" ->
        # Send email and move
        case EmailTemplates.send_stage_email(
               socket.assigns.email_preview.template,
               pending.application.candidate,
               pending.application.job,
               %{
                 candidate_name: pending.application.candidate.name,
                 job_title: pending.application.job.title,
                 company_name: socket.assigns.current_tenant.name,
                 stage_name: pending.stage.name,
                 recruiter_name: socket.assigns.current_user.name
               }
             ) do
          :ok ->
            case Pipeline.move_application(pending.application, pending.stage.id) do
              {:ok, _application} ->
                applications_by_stage = Pipeline.list_applications_by_stage(socket.assigns.job.id)

                {:noreply,
                 socket
                 |> assign(applications_by_stage: applications_by_stage)
                 |> assign(show_email_dialog: false, pending_stage_move: nil, email_preview: nil)
                 |> put_flash(:info, "Candidate moved and email sent")}

              {:error, _changeset} ->
                {:noreply, put_flash(socket, :error, "Failed to move candidate")}
            end

          {:error, _reason} ->
            {:noreply, put_flash(socket, :error, "Failed to send email")}
        end

      "skip" ->
        # Skip email, just move
        case Pipeline.move_application(pending.application, pending.stage.id) do
          {:ok, _application} ->
            applications_by_stage = Pipeline.list_applications_by_stage(socket.assigns.job.id)

            {:noreply,
             socket
             |> assign(applications_by_stage: applications_by_stage)
             |> assign(show_email_dialog: false, pending_stage_move: nil, email_preview: nil)
             |> put_flash(:info, "Candidate moved without email")}

          {:error, _changeset} ->
            {:noreply, put_flash(socket, :error, "Failed to move candidate")}
        end

      "cancel" ->
        {:noreply,
         socket
         |> assign(show_email_dialog: false, pending_stage_move: nil, email_preview: nil)}
    end
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
end
