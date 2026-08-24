defmodule Treby.Interviews do
  @moduledoc """
  Context for interview scheduling and management.
  """

  import Ecto.Query
  alias Treby.Repo
  alias Treby.Interviews.InterviewEvent
  alias Treby.Interviews.BookingToken

  def list_upcoming_for_user(user_id) do
    now = DateTime.utc_now()

    InterviewEvent
    |> where(
      [e],
      e.interviewer_id == ^user_id and e.status == "scheduled" and e.start_at_utc > ^now
    )
    |> order_by([e], asc: e.start_at_utc)
    |> preload([:interviewer, :scheduled_by, application: [:candidate, :job]])
    |> Repo.all()
  end

  def list_upcoming_for_tenant(tenant_id) do
    now = DateTime.utc_now()

    InterviewEvent
    |> where([e], e.tenant_id == ^tenant_id and e.status == "scheduled" and e.start_at_utc > ^now)
    |> order_by([e], asc: e.start_at_utc)
    |> preload([:interviewer, :scheduled_by, application: [:candidate, :job]])
    |> Repo.all()
  end

  def list_for_application(application_id) do
    InterviewEvent
    |> where([e], e.application_id == ^application_id)
    |> order_by([e], desc: e.start_at_utc)
    |> preload([:interviewer, :scheduled_by])
    |> Repo.all()
  end

  def get_event!(id) do
    InterviewEvent
    |> Repo.get!(id)
    |> Repo.preload([:application, :interviewer, :scheduled_by, :tenant])
  end

  def schedule_interview(attrs) do
    result =
      %InterviewEvent{}
      |> InterviewEvent.changeset(attrs)
      |> Repo.insert()

    case result do
      {:ok, event} ->
        # Move application to "Interview" stage
        move_application_to_interview(event.application_id)

        # Send notifications
        send_interview_notifications(event)

        # Log the event
        event = Repo.preload(event, [:application, :interviewer])

        Treby.Activities.log_event(
          "interview_scheduled",
          "application",
          event.application_id,
          %{
            interviewer_name: event.interviewer && event.interviewer.name,
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
    # Delete Google Calendar event if we have the event ID
    if event.google_event_id do
      Treby.Calendar.delete_event(event.scheduled_by_id, event.google_event_id)
    end

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
    event = Repo.preload(event, [:application, :interviewer, :scheduled_by])
    application = Repo.preload(event.application, [:candidate, :job])
    candidate = application.candidate
    job = application.job
    interviewer = event.interviewer
    meet_link = event.video_conf_url

    # Email notifications
    Treby.SchedulingEmail.interview_scheduled_candidate(
      candidate,
      interviewer,
      job,
      meet_link,
      event.start_at_utc
    )
    |> Treby.Mailer.deliver()

    Treby.SchedulingEmail.interview_scheduled_interviewer(
      interviewer,
      candidate,
      job,
      meet_link,
      event.start_at_utc
    )
    |> Treby.Mailer.deliver()
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
    |> preload([:application, :interviewer, :tenant])
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
