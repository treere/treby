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
      weekly_stats: weekly_stats(tenant_id)
    }
  end

  def upcoming_interviews(tenant_id, user_id, days \\ 7) do
    cutoff = DateTime.add(DateTime.utc_now(), days, :day)

    Treby.Interviews.InterviewEvent
    |> join(:inner, [e], a in assoc(e, :application))
    |> where([e, a], a.tenant_id == ^tenant_id and e.interviewer_id == ^user_id)
    |> where(
      [e],
      e.status == "scheduled" and e.start_at_utc > ^DateTime.utc_now() and
        e.start_at_utc <= ^cutoff
    )
    |> preload([:application, :interviewer])
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
      |> where(
        [j],
        j.tenant_id == ^tenant_id and j.status == "open" and not is_nil(j.pipeline_id)
      )
      |> Repo.all()

    Enum.map(jobs, fn job ->
      stages =
        Treby.Pipeline.PipelineStage
        |> where([ps], ps.pipeline_id == ^job.pipeline_id)
        |> order_by([ps], ps.position)
        |> Repo.all()

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
