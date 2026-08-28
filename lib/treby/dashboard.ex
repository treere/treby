defmodule Treby.Dashboard do
  @moduledoc """
  Context for dashboard data aggregation.
  """

  import Ecto.Query
  alias Treby.Repo

  def get_dashboard_data(tenant_id, user_id) do
    %{
      upcoming_interviews: upcoming_interviews(tenant_id, user_id),
      stale_candidates: stale_candidates(tenant_id),
      pipeline_snapshot: pipeline_snapshot(tenant_id),
      weekly_stats: weekly_stats(tenant_id),
      my_actions: my_actions(tenant_id, user_id)
    }
  end

  @doc """
  Aggregates the current user's outstanding hiring actions for the dashboard.

  Returns a map with:
    - `:pending_scorecards` — interview events where the user is an examiner and
      their scorecard has not been submitted yet.
    - `:waiting_on_others` — applications at an interview stage that are blocked
      by other people's outstanding work (other examiners' missing scorecards or
      an interview not yet completed).
  """
  def my_actions(tenant_id, user_id) do
    %{
      pending_scorecards: pending_scorecards(tenant_id, user_id),
      waiting_on_others: waiting_on_others(tenant_id, user_id)
    }
  end

  defp pending_scorecards(tenant_id, user_id) do
    events =
      Treby.Interviews.InterviewEvent
      |> join(:inner, [e], ee in Treby.Interviews.EventExaminer,
        on: ee.interview_event_id == e.id
      )
      |> where([e, ee], e.tenant_id == ^tenant_id and ee.user_id == ^user_id)
      |> preload([e, ee], event_examiners: [:user], application: [:candidate, :job])
      |> order_by([e], asc: e.start_at_utc)
      |> Repo.all()

    event_ids = Enum.map(events, & &1.id)

    submitted_ids =
      if event_ids == [] do
        MapSet.new()
      else
        Treby.Scorecards.Scorecard
        |> where([s], s.interview_event_id in ^event_ids and s.interviewer_id == ^user_id)
        |> select([s], s.interview_event_id)
        |> Repo.all()
        |> MapSet.new()
      end

    events
    |> Enum.reject(fn e -> MapSet.member?(submitted_ids, e.id) end)
    |> Enum.map(fn e ->
      application = e.application

      %{
        event_id: e.id,
        candidate_id: application && application.candidate_id,
        candidate_name: application && application.candidate && application.candidate.name,
        job_title: application && application.job && application.job.title,
        start_at: e.start_at_utc
      }
    end)
  end

  defp waiting_on_others(tenant_id, user_id) do
    Treby.Pipeline.Application
    |> where([a], a.tenant_id == ^tenant_id)
    |> preload([:pipeline_stage, :candidate, :job])
    |> Repo.all()
    |> Enum.flat_map(fn app ->
      if app.pipeline_stage && app.pipeline_stage.stage_type == "interview" do
        blockers = Treby.Pipeline.current_state(app).blockers

        relevant =
          Enum.filter(blockers, fn b ->
            case b.kind do
              :interview_not_completed ->
                true

              :scorecard_pending ->
                b.assignee != nil and b.assignee.user_id != user_id

              _ ->
                false
            end
          end)

        if relevant == [] do
          []
        else
          [
            %{
              application_id: app.id,
              candidate_name: app.candidate && app.candidate.name,
              job_title: app.job && app.job.title,
              blockers: Enum.map(relevant, & &1.label)
            }
          ]
        end
      else
        []
      end
    end)
  end

  def upcoming_interviews(tenant_id, user_id, days \\ 7) do
    cutoff = DateTime.add(DateTime.utc_now(), days, :day)

    Treby.Interviews.InterviewEvent
    |> join(:inner, [e], a in assoc(e, :application))
    |> join(:inner, [e], ee in Treby.Interviews.EventExaminer, on: ee.interview_event_id == e.id)
    |> where(
      [e, a, ee],
      a.tenant_id == ^tenant_id and ee.user_id == ^user_id and ee.status == "scheduled"
    )
    |> where(
      [e],
      e.status == "scheduled" and e.start_at_utc > ^DateTime.utc_now() and
        e.start_at_utc <= ^cutoff
    )
    |> preload([e, a, ee], event_examiners: [:user], application: [:candidate, :job])
    |> order_by([e], asc: e.start_at_utc)
    |> Repo.all()
  end

  def stale_candidates(tenant_id, threshold_days \\ 5) do
    cutoff = DateTime.add(DateTime.utc_now(), -threshold_days, :day)

    last_activity =
      from(al in Treby.Activities.ActivityLog,
        where: al.entity_type == "application",
        group_by: al.entity_id,
        select: %{
          entity_id: al.entity_id,
          last_activity: max(al.inserted_at)
        }
      )

    application_ids =
      from(a in Treby.Pipeline.Application,
        left_join: la in subquery(last_activity),
        on: la.entity_id == a.id,
        where: a.tenant_id == ^tenant_id,
        where: is_nil(la.last_activity) or la.last_activity < ^cutoff,
        select: a.id
      )
      |> Repo.all()

    Treby.Pipeline.Application
    |> where([a], a.id in ^application_ids)
    |> preload([:candidate, :pipeline_stage, :job])
    |> order_by([a], asc: a.updated_at)
    |> Repo.all()
  end

  def pipeline_snapshot(tenant_id) do
    jobs =
      Treby.Jobs.Job
      |> where([j], j.tenant_id == ^tenant_id and j.status == "open")
      |> Repo.all()

    Enum.map(jobs, fn job ->
      stages = Treby.Pipeline.list_pipeline_stages_for_job(job.id)

      stage_counts =
        Enum.map(stages, fn stage ->
          count =
            Treby.Pipeline.Application
            |> where([a], a.job_id == ^job.id and a.pipeline_stage_id == ^stage.id)
            |> select([a], count(a.id))
            |> Repo.one()

          %{stage: stage, count: count}
        end)

      %{job: job, stages: stage_counts}
    end)
  end

  def weekly_stats(tenant_id) do
    week_start =
      DateTime.utc_now()
      |> DateTime.to_date()
      |> Date.beginning_of_week(:monday)
      |> DateTime.new!(~T[00:00:00])

    applications_this_week =
      Treby.Pipeline.Application
      |> where([a], a.tenant_id == ^tenant_id and a.inserted_at >= ^week_start)
      |> select([a], count(a.id))
      |> Repo.one()

    interviews_this_week =
      Treby.Interviews.InterviewEvent
      |> join(:inner, [e], a in assoc(e, :application))
      |> where([e, a], a.tenant_id == ^tenant_id and e.inserted_at >= ^week_start)
      |> select([e], count(e.id))
      |> Repo.one()

    offers_this_week =
      Treby.Pipeline.Application
      |> join(:inner, [a], ps in assoc(a, :pipeline_stage))
      |> where(
        [a, ps],
        a.tenant_id == ^tenant_id and ps.stage_type == "offer" and a.updated_at >= ^week_start
      )
      |> select([a], count(a.id))
      |> Repo.one()

    hires_this_week =
      Treby.Pipeline.Application
      |> join(:inner, [a], ps in assoc(a, :pipeline_stage))
      |> where(
        [a, ps],
        a.tenant_id == ^tenant_id and ps.stage_type == "hired" and a.updated_at >= ^week_start
      )
      |> select([a], count(a.id))
      |> Repo.one()

    %{
      applications: applications_this_week,
      interviews: interviews_this_week,
      offers: offers_this_week,
      hires: hires_this_week
    }
  end
end
