defmodule Treby.Interviews do
  @moduledoc """
  Context for interview scheduling and management.
  """

  import Ecto.Query
  alias Treby.Repo
  alias Treby.Interviews.InterviewEvent
  alias Treby.Interviews.EventExaminer
  alias Treby.Notifications.Email, as: NotificationEmail

  def list_upcoming_for_user(user_id) do
    now = DateTime.utc_now()

    InterviewEvent
    |> join(:inner, [e], ee in EventExaminer, on: ee.interview_event_id == e.id)
    |> where([e, ee], ee.user_id == ^user_id and ee.status == "scheduled")
    |> where([e], e.status == "scheduled" and e.start_at_utc > ^now)
    |> order_by([e], asc: e.start_at_utc)
    |> preload([e, ee],
      event_examiners: [:user],
      scheduled_by: [],
      application: [:candidate, :job]
    )
    |> Repo.all()
  end

  def list_upcoming_for_tenant(tenant_id) do
    now = DateTime.utc_now()

    InterviewEvent
    |> where([e], e.tenant_id == ^tenant_id and e.status == "scheduled" and e.start_at_utc > ^now)
    |> order_by([e], asc: e.start_at_utc)
    |> preload([:event_examiners, :scheduled_by, application: [:candidate, :job]])
    |> Repo.all()
  end

  def list_for_application(application_id) do
    InterviewEvent
    |> where([e], e.application_id == ^application_id)
    |> order_by([e], desc: e.start_at_utc)
    |> preload([:event_examiners, :scheduled_by])
    |> Repo.all()
  end

  def get_event!(id) do
    InterviewEvent
    |> Repo.get!(id)
    |> Repo.preload([:application, :event_examiners, :scheduled_by, :tenant])
  end

  def schedule_interview(attrs) do
    examiner_ids = Map.get(attrs, :examiner_ids) || Map.get(attrs, "examiner_ids", [])
    attrs = Map.drop(attrs, [:examiner_ids, "examiner_ids"])

    result =
      %InterviewEvent{}
      |> InterviewEvent.changeset(attrs)
      |> Repo.insert()

    case result do
      {:ok, event} ->
        # Create event_examiner records for each examiner
        Enum.each(examiner_ids, fn user_id ->
          %EventExaminer{}
          |> EventExaminer.changeset(%{interview_event_id: event.id, user_id: user_id})
          |> Repo.insert!()
        end)

        # Move application to "Interview" stage
        move_application_to_interview(event.application_id)

        # Send notifications
        send_interview_notifications(event)

        # Log the event
        event = Repo.preload(event, [:application, event_examiners: :user])

        examiner_names =
          event.event_examiners
          |> Enum.map(fn ee -> ee.user && ee.user.name end)
          |> Enum.reject(&is_nil/1)
          |> Enum.join(", ")

        Treby.Activities.log_event(
          "interview_scheduled",
          "application",
          event.application_id,
          %{
            examiner_names: examiner_names,
            start_at: event.start_at_utc,
            tenant_id: event.tenant_id
          }
        )

        Treby.Audit.log_event("interview.scheduled", "interview_event", event.id, %{
          tenant_id: event.tenant_id,
          actor_id: event.scheduled_by_id,
          metadata: %{
            after: %{application_id: event.application_id, start_at: event.start_at_utc}
          }
        })

        {:ok, event}

      error ->
        error
    end
  end

  @doc """
  Marks a scheduled interview as completed explicitly.

  Transitions the event status "scheduled" → "completed". This does NOT move the
  application to another stage; advancement remains a separate, explicit action.
  """
  def complete_interview(%InterviewEvent{} = event), do: complete_interview(event, nil)

  def complete_interview(%InterviewEvent{} = event, actor) do
    event = Repo.preload(event, [:application])

    case event
         |> InterviewEvent.changeset(%{status: "completed"})
         |> Repo.update() do
      {:ok, completed_event} ->
        Treby.Activities.log_event(
          "interview_completed",
          "application",
          event.application_id,
          %{
            completed_by: actor && actor.id,
            tenant_id: event.tenant_id
          }
        )

        Treby.Audit.log_event("interview.completed", "interview_event", completed_event.id, %{
          tenant_id: completed_event.tenant_id,
          actor_id: actor && actor.id,
          metadata: %{before: %{status: "scheduled"}, after: %{status: "completed"}}
        })

        # Broadcast so pipeline boards re-stream without manual reload
        try do
          Phoenix.PubSub.broadcast(
            Treby.PubSub,
            "pipeline:#{event.application.job_id}",
            {:pipeline_updated, event.application.job_id}
          )
        rescue
          _ -> :ok
        catch
          _ -> :ok
        end

        {:ok, completed_event}

      error ->
        error
    end
  end

  def cancel_interview(%InterviewEvent{} = event) do
    event = Repo.preload(event, [:event_examiners, :application])

    # Delete the external calendar event using the calendar owner's connection
    if event.provider_event_id && event.calendar_provider && event.calendar_owner_id do
      Treby.Calendar.delete_event(
        event.calendar_owner_id,
        event.calendar_provider,
        event.provider_event_id
      )
    end

    # Update all event examiner statuses to cancelled
    event.event_examiners
    |> Enum.each(fn ee ->
      ee
      |> EventExaminer.changeset(%{status: "cancelled"})
      |> Repo.update!()
    end)

    result =
      event
      |> InterviewEvent.changeset(%{status: "cancelled"})
      |> Repo.update()

    case result do
      {:ok, cancelled_event} ->
        Treby.Activities.log_event(
          "interview_cancelled",
          "application",
          event.application_id,
          %{
            cancelled_by: event.scheduled_by_id,
            tenant_id: event.tenant_id
          }
        )

        Treby.Audit.log_event("interview.cancelled", "interview_event", cancelled_event.id, %{
          tenant_id: cancelled_event.tenant_id,
          metadata: %{before: %{status: "scheduled"}, after: %{status: "cancelled"}}
        })

        {:ok, cancelled_event}

      error ->
        error
    end
  end

  defp send_interview_notifications(event) do
    event = Repo.preload(event, [:application, :event_examiners, :scheduled_by])
    application = Repo.preload(event.application, [:candidate, :job])
    candidate = application.candidate
    job = application.job
    meet_link = event.video_conf_url

    # Use the first examiner as the interviewer; fall back to scheduled_by
    interviewer =
      case event.event_examiners do
        [%EventExaminer{} = first | _] ->
          Repo.preload(first, :user).user

        _ ->
          Repo.preload(event, :scheduled_by).scheduled_by
      end

    # Post interview details into the candidate's portal conversation
    post_interview_message(event, application, candidate, interviewer, meet_link)

    # Notify each examiner in-app via the activity log
    event.event_examiners
    |> Enum.each(fn event_examiner ->
      examiner = Repo.preload(event_examiner, :user).user

      if examiner do
        Treby.Activities.log_event(
          "interview_scheduled",
          "interview_event",
          event.id,
          %{
            examiner_id: examiner.id,
            tenant_id: event.tenant_id,
            candidate_name: candidate.name,
            job_title: job.title,
            start_at: event.start_at_utc,
            meet_link: meet_link
          }
        )
      end
    end)
  end

  defp post_interview_message(event, application, candidate, interviewer, meet_link) do
    interviewer_name = if interviewer, do: interviewer.name, else: "To be determined"
    start_at = event.start_at_utc

    conversation =
      case Treby.CandidatePortal.list_conversations_for_application(
             application.id,
             event.tenant_id
           )
           |> Enum.find(&(&1.context == "application")) do
        nil ->
          {:ok, conversation} =
            Treby.CandidatePortal.create_conversation(%{
              candidate_id: candidate.id,
              tenant_id: event.tenant_id,
              application_id: application.id,
              subject: application.job.title,
              context: "application"
            })

          conversation

        conversation ->
          conversation
      end

    body =
      "Your interview for #{application.job.title} has been scheduled.\n" <>
        "Interviewer: #{interviewer_name}\n" <>
        "Date & Time: #{format_datetime(start_at)}\n" <>
        "Meeting Link: #{meet_link}"

    Treby.CandidatePortal.send_message(%{
      sender_type: "system",
      conversation_id: conversation.id,
      body: body,
      message_type: "interview_invite",
      metadata: %{
        "interview_event_id" => event.id,
        "meet_link" => meet_link,
        "start_at" => start_at,
        "interviewer_name" => interviewer_name
      }
    })

    # Optional notification ping to the candidate
    if Treby.CandidatePortal.notification_enabled?(candidate, "interview_update") do
      tenant = Repo.get!(Treby.Tenants.Tenant, event.tenant_id)

      email =
        NotificationEmail.notification_ping(
          candidate,
          tenant,
          conversation.id,
          "interview_update",
          %{"job_title" => application.job.title}
        )

      Treby.Mailer.deliver(email)
    end
  end

  defp format_datetime(dt) do
    Elixir.Calendar.strftime(dt, "%B %d, %Y at %H:%M UTC")
  end

  defp move_application_to_interview(application_id) do
    alias Treby.Pipeline

    application = Pipeline.get_application!(application_id)
    job = Treby.Jobs.get_job!(application.job_id)

    # Find the interview stage for this job's pipeline
    interview_stage =
      Pipeline.list_pipeline_stages_for_job(job.id)
      |> Enum.find(&(&1.stage_type == "interview"))

    if interview_stage do
      Pipeline.move_application(application, interview_stage.id)
    end
  end

  @doc """
  Finds substitute examiners for a cancelled event examiner.

  Returns a list of eligible examiners who have overlapping availability
  for the event's time slot.
  """
  def find_substitutes(%EventExaminer{} = cancelled_ee) do
    event =
      cancelled_ee
      |> Repo.preload([:application, event_examiners: [:user]])

    application = Repo.preload(event.application, [:job])
    job = application.job
    pipeline_stages = Treby.Pipeline.list_pipeline_stages_for_job(job.id)

    interview_stage = Enum.find(pipeline_stages, &(&1.stage_type == "interview"))

    if interview_stage do
      # Get currently scheduled examiners (excluding the cancelled one)
      current_examiner_ids =
        event.event_examiners
        |> Enum.filter(&(&1.id != cancelled_ee.id and &1.status == "scheduled"))
        |> Enum.map(& &1.user_id)

      # Get all eligible examiners for this stage
      eligible_examiners = Treby.Pipeline.list_eligible_examiners(interview_stage)

      # Find examiners not already assigned to this event
      candidate_ids =
        eligible_examiners
        |> Enum.map(& &1.user_id)
        |> Enum.reject(&(&1 in current_examiner_ids or &1 == cancelled_ee.user_id))

      if candidate_ids != [] do
        # Compute overlapping slots for the event time
        slot_range = %{
          from: DateTime.to_date(event.start_at_utc),
          to: DateTime.to_date(event.start_at_utc)
        }

        min_examiners = interview_stage.min_examiners || 1

        available =
          Treby.Availability.compute_overlapping_slots(
            current_examiner_ids ++ candidate_ids,
            min_examiners,
            slot_range
          )

        # Return examiners who are available for this specific slot
        case available do
          slots when is_list(slots) ->
            slots
            |> Enum.flat_map(& &1.available_examiners)
            |> Enum.uniq()
            |> Enum.reject(&(&1 in current_examiner_ids))
            |> Enum.map(fn user_id ->
              Enum.find(eligible_examiners, &(&1.user_id == user_id))
            end)
            |> Enum.reject(&is_nil/1)

          {:error, _reason} ->
            []
        end
      else
        []
      end
    else
      []
    end
  end

  @doc """
  Notifies advancers when no substitute is found for a cancelled examiner.
  """
  def notify_advancers_no_substitute(%EventExaminer{} = cancelled_ee) do
    event =
      cancelled_ee
      |> Repo.preload([:application, :scheduled_by])

    application = Repo.preload(event.application, [:job])
    job = application.job
    pipeline_stages = Treby.Pipeline.list_pipeline_stages_for_job(job.id)

    interview_stage = Enum.find(pipeline_stages, &(&1.stage_type == "interview"))

    if interview_stage do
      advancers = Treby.Pipeline.list_advancers(interview_stage)

      Enum.each(advancers, fn advancer ->
        Treby.Activities.log_event(
          "no_substitute_found",
          "application",
          event.application_id,
          %{
            user_id: advancer.user_id,
            tenant_id: event.tenant_id,
            message:
              "No eligible substitute was found for the cancelled interview on #{Date.to_string(DateTime.to_date(event.start_at_utc))}. Please manually assign a replacement."
          }
        )
      end)
    end
  end

  @doc """
  Returns scorecard completion status for an interview event.

  Returns %{completed: N, total: M, pending: [%{user_id: ..., name: ...}]}
  """
  def scorecard_completion_status(%InterviewEvent{} = event) do
    event = Repo.preload(event, [:scorecards, event_examiners: :user])

    total = length(event.event_examiners)

    completed_interviewer_ids =
      event.scorecards
      |> Enum.map(& &1.interviewer_id)
      |> MapSet.new()

    completed =
      event.event_examiners
      |> Enum.count(&MapSet.member?(completed_interviewer_ids, &1.user_id))

    pending =
      event.event_examiners
      |> Enum.reject(&MapSet.member?(completed_interviewer_ids, &1.user_id))
      |> Enum.map(fn ee ->
        user = ee.user
        %{user_id: ee.user_id, name: user && user.name}
      end)

    %{completed: completed, total: total, pending: pending}
  end
end
