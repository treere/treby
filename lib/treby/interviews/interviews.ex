defmodule Treby.Interviews do
  @moduledoc """
  Context for interview scheduling and management.
  """

  import Ecto.Query
  alias Treby.Repo
  alias Treby.Interviews.InterviewEvent
  alias Treby.Interviews.EventExaminer
  alias Treby.Interviews.BookingToken

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

        {:ok, event}

      error ->
        error
    end
  end

  def cancel_interview(%InterviewEvent{} = event) do
    event = Repo.preload(event, [:event_examiners, :application])

    # Delete Google Calendar event if we have the event ID
    if event.google_event_id do
      Treby.Calendar.delete_event(event.scheduled_by_id, event.google_event_id)
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

    # Notify candidate once
    Treby.SchedulingEmail.interview_scheduled_candidate(
      candidate,
      interviewer,
      job,
      meet_link,
      event.start_at_utc
    )
    |> Treby.Mailer.deliver()

    # Notify each examiner
    event.event_examiners
    |> Enum.each(fn event_examiner ->
      examiner = Repo.preload(event_examiner, :user).user

      if examiner do
        Treby.SchedulingEmail.interview_scheduled_interviewer(
          examiner,
          candidate,
          job,
          meet_link,
          event.start_at_utc
        )
        |> Treby.Mailer.deliver()
      end
    end)
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
        available
        |> Enum.flat_map(& &1.available_examiners)
        |> Enum.uniq()
        |> Enum.reject(&(&1 in current_examiner_ids))
        |> Enum.map(fn user_id ->
          Enum.find(eligible_examiners, &(&1.user_id == user_id))
        end)
        |> Enum.reject(&is_nil/1)
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

  # Booking token functions

  def generate_booking_token(attrs) do
    token = :crypto.strong_rand_bytes(32) |> Base.url_encode64(padding: false)
    expires_at = DateTime.utc_now() |> DateTime.add(7, :day)

    %BookingToken{}
    |> BookingToken.changeset(Map.merge(attrs, %{token: token, expires_at: expires_at}))
    |> Repo.insert()
  end

  def get_booking_token(token) do
    BookingToken
    |> where([t], t.token == ^token and is_nil(t.used_at))
    |> where([t], t.expires_at > ^DateTime.utc_now())
    |> preload([:application, :interviewer, :pipeline_stage, :tenant])
    |> preload(application: [:job, :candidate])
    |> Repo.one()
  end

  def use_booking_token(%BookingToken{} = token) do
    token
    |> BookingToken.changeset(%{used_at: DateTime.utc_now()})
    |> Repo.update()
  end

  @doc """
  Generates a booking token and returns the absolute self-scheduling URL.
  """
  def generate_booking_link(attrs) do
    with {:ok, %BookingToken{} = token} <- generate_booking_token(attrs),
         tenant <- Repo.preload(token, [:tenant]).tenant do
      {:ok, absolute_booking_url(tenant, token.token)}
    end
  end

  @doc """
  Builds the absolute booking URL for a tenant slug and token.
  """
  def absolute_booking_url(%Treby.Tenants.Tenant{} = tenant, token) do
    TrebyWeb.Endpoint.url() <> "/#{tenant.slug}/schedule/#{token}"
  end
end
