defmodule Treby.Pipeline.Analytics do
  @moduledoc """
  Pipeline analytics: stage counts, time-to-hire, conversion, time-in-stage,
  and source breakdown.

  Extracted from `Treby.Pipeline`. Tenant-scoped variants share a single
  implementation via private scoped-query helpers. `Treby.Pipeline` remains
  the public facade.
  """

  import Ecto.Query, warn: false
  alias Treby.Repo
  alias Treby.Pipeline.Pipeline, as: PipelineDef
  alias Treby.Pipeline.PipelineStage
  alias Treby.Pipeline.Application
  alias Treby.Pipeline.Stages

  # Scoped helpers

  defp scoped_pipeline_ids(nil), do: nil

  defp scoped_pipeline_ids(tenant_id) do
    PipelineDef
    |> where([p], p.tenant_id == ^tenant_id)
    |> select([p], p.id)
    |> Repo.all()
  end

  defp maybe_tenant_filter(query, nil), do: query

  defp maybe_tenant_filter(query, tenant_id) do
    where(query, [a], a.tenant_id == ^tenant_id)
  end

  # Stage counts

  def pipeline_counts_per_stage(nil) do
    do_pipeline_counts_all(nil)
  end

  def pipeline_counts_per_stage(pipeline_id) do
    stages =
      PipelineStage
      |> where([ps], ps.pipeline_id == ^pipeline_id)
      |> order_by([ps], ps.position)
      |> Repo.all()

    counts_map = grouped_application_counts(Enum.map(stages, & &1.id), nil)

    Enum.map(stages, fn stage ->
      %{stage: stage, count: Map.get(counts_map, stage.id, 0)}
    end)
  end

  defp do_pipeline_counts_all(tenant_id) do
    stages =
      case scoped_pipeline_ids(tenant_id) do
        nil ->
          PipelineStage
          |> order_by([ps], ps.position)
          |> Repo.all()

        ids ->
          PipelineStage
          |> where([ps], ps.pipeline_id in ^ids)
          |> order_by([ps], ps.position)
          |> Repo.all()
      end

    counts_map =
      grouped_application_counts(Enum.map(stages, & &1.id), tenant_id)

    stages
    |> Enum.group_by(& &1.name)
    |> Enum.map(fn {_name, grouped} ->
      count =
        Enum.reduce(grouped, 0, fn stage, acc ->
          acc + Map.get(counts_map, stage.id, 0)
        end)

      %{stage: List.first(grouped), count: count}
    end)
    |> Enum.sort_by(& &1.stage.position)
  end

  defp grouped_application_counts([], _tenant_id), do: %{}

  defp grouped_application_counts(stage_ids, tenant_id) do
    Application
    |> where([a], a.pipeline_stage_id in ^stage_ids)
    |> maybe_tenant_filter(tenant_id)
    |> group_by([a], a.pipeline_stage_id)
    |> select([a], %{stage_id: a.pipeline_stage_id, count: count(a.id)})
    |> Repo.all()
    |> Map.new(&{&1.stage_id, &1.count})
  end

  def pipeline_counts_per_stage_for_job(job_id) do
    stages = Stages.list_pipeline_stages_for_job(job_id)

    Application
    |> where([a], a.job_id == ^job_id)
    |> group_by([a], a.pipeline_stage_id)
    |> select([a], %{stage_id: a.pipeline_stage_id, count: count(a.id)})
    |> Repo.all()
    |> then(fn counts ->
      counts_map = Map.new(counts, &{&1.stage_id, &1.count})

      Enum.map(stages, fn stage ->
        %{stage: stage, count: Map.get(counts_map, stage.id, 0)}
      end)
    end)
  end

  # Time to hire

  def average_time_to_hire(nil) do
    do_average_time_to_hire(nil)
  end

  def average_time_to_hire(pipeline_id) do
    hired_stage =
      PipelineStage
      |> where([ps], ps.pipeline_id == ^pipeline_id and ps.stage_type == "hired")
      |> Repo.one()

    case hired_stage do
      nil ->
        nil

      stage ->
        Application
        |> where([a], a.pipeline_stage_id == ^stage.id)
        |> select([a], avg(fragment("EXTRACT(DAY FROM (? - ?))", a.updated_at, a.inserted_at)))
        |> Repo.one()
    end
  end

  defp do_average_time_to_hire(tenant_id) do
    hired_stages =
      case tenant_id do
        nil ->
          PipelineStage
          |> where([ps], ps.stage_type == "hired")
          |> select([ps], ps.id)
          |> Repo.all()

        _ ->
          PipelineStage
          |> join(:inner, [ps], p in PipelineDef, on: ps.pipeline_id == p.id)
          |> where([ps, p], p.tenant_id == ^tenant_id and ps.stage_type == "hired")
          |> select([ps, _p], ps.id)
          |> Repo.all()
      end

    case hired_stages do
      [] ->
        nil

      stage_ids ->
        Application
        |> where([a], a.pipeline_stage_id in ^stage_ids)
        |> maybe_tenant_filter(tenant_id)
        |> select([a], avg(fragment("EXTRACT(DAY FROM (? - ?))", a.updated_at, a.inserted_at)))
        |> Repo.one()
    end
  end

  # Conversion rates

  def stage_conversion_rates(nil) do
    do_stage_conversion_by_type(nil)
  end

  def stage_conversion_rates(pipeline_id) do
    stages = Stages.list_pipeline_stages(pipeline_id)

    stages
    |> Enum.chunk_every(2, 1, :discard)
    |> Enum.flat_map(fn [from_stage, to_stage] ->
      from_count =
        Application
        |> where([a], a.pipeline_stage_id == ^from_stage.id)
        |> select([a], count(a.id))
        |> Repo.one()

      to_count =
        Application
        |> where([a], a.pipeline_stage_id == ^to_stage.id)
        |> select([a], count(a.id))
        |> Repo.one()

      rate = if from_count > 0, do: round(to_count / from_count * 100), else: 0

      [
        %{
          from: from_stage,
          to: to_stage,
          rate: rate
        }
      ]
    end)
  end

  defp do_stage_conversion_by_type(tenant_id) do
    stage_type_order = ["new", "interview", "offer", "hired"]

    stages_by_type =
      case tenant_id do
        nil ->
          PipelineStage
          |> where([ps], not is_nil(ps.stage_type))
          |> Repo.all()

        _ ->
          PipelineStage
          |> join(:inner, [ps], p in PipelineDef, on: ps.pipeline_id == p.id)
          |> where([ps, p], p.tenant_id == ^tenant_id and not is_nil(ps.stage_type))
          |> Repo.all()
      end
      |> Enum.group_by(& &1.stage_type)

    stage_type_order
    |> Enum.chunk_every(2, 1, :discard)
    |> Enum.flat_map(fn [from_type, to_type] ->
      from_stage_ids = stages_by_type |> Map.get(from_type, []) |> Enum.map(& &1.id)
      to_stage_ids = stages_by_type |> Map.get(to_type, []) |> Enum.map(& &1.id)

      from_count =
        if from_stage_ids == [] do
          0
        else
          Application
          |> where([a], a.pipeline_stage_id in ^from_stage_ids)
          |> maybe_tenant_filter(tenant_id)
          |> select([a], count(a.id))
          |> Repo.one()
        end

      to_count =
        if to_stage_ids == [] do
          0
        else
          Application
          |> where([a], a.pipeline_stage_id in ^to_stage_ids)
          |> maybe_tenant_filter(tenant_id)
          |> select([a], count(a.id))
          |> Repo.one()
        end

      from_stage = %{name: String.capitalize(from_type), color: "#6B7280", id: from_type}
      to_stage = %{name: String.capitalize(to_type), color: "#6B7280", id: to_type}
      rate = if from_count > 0, do: round(to_count / from_count * 100), else: 0

      [%{from: from_stage, to: to_stage, rate: rate}]
    end)
  end

  # Time in stage (trailing window, see @metrics_window_days)

  @metrics_window_days 90

  @doc """
  Trailing window in days for time-in-stage metrics.
  """
  @spec metrics_window_days() :: pos_integer()
  def metrics_window_days, do: @metrics_window_days

  def time_in_stage_metrics(tenant_id, nil) do
    application_ids =
      Application
      |> join(:inner, [a], j in Treby.Jobs.Job, on: a.job_id == j.id)
      |> where([a, j], j.tenant_id == ^tenant_id)
      |> select([a], a.id)
      |> Repo.all()

    all_stages = PipelineStage |> order_by([ps], ps.position) |> Repo.all()
    do_time_in_stage_metrics(application_ids, all_stages)
  end

  def time_in_stage_metrics(_tenant_id, pipeline_id) do
    stages = Stages.list_pipeline_stages(pipeline_id)

    application_ids =
      Application
      |> join(:inner, [a], ps in PipelineStage, on: a.pipeline_stage_id == ps.id)
      |> where([a, ps], ps.pipeline_id == ^pipeline_id)
      |> select([a], a.id)
      |> Repo.all()

    do_time_in_stage_metrics(application_ids, stages)
  end

  defp do_time_in_stage_metrics([], _stages), do: []

  defp do_time_in_stage_metrics(application_ids, stages) do
    alias Treby.Activities.ActivityLog

    window_start = DateTime.utc_now() |> DateTime.add(-@metrics_window_days, :day)

    events =
      ActivityLog
      |> where(
        [a],
        a.action == "application_stage_changed" and
          a.entity_type == "application" and
          a.entity_id in ^application_ids and
          a.inserted_at >= ^window_start
      )
      |> order_by([a], asc: a.inserted_at)
      |> Repo.all()

    events_by_app = Enum.group_by(events, & &1.entity_id)

    stage_durations =
      Enum.flat_map(events_by_app, fn {_app_id, app_events} ->
        app_events
        |> Enum.chunk_every(2, 1, :discard)
        |> Enum.flat_map(fn
          [event1, event2] ->
            old_stage_name = event1.metadata["new_stage"]
            duration_days = DateTime.diff(event2.inserted_at, event1.inserted_at, :day)
            [%{stage_name: old_stage_name, duration_days: duration_days}]

          [_single_event] ->
            stage_name = List.last(app_events).metadata["new_stage"]

            duration_days =
              DateTime.diff(DateTime.utc_now(), List.last(app_events).inserted_at, :day)

            [%{stage_name: stage_name, duration_days: duration_days}]
        end)
      end)

    stage_durations
    |> Enum.group_by(& &1.stage_name)
    |> Enum.map(fn {stage_name, durations} ->
      avg_days =
        durations |> Enum.map(& &1.duration_days) |> then(fn ds -> Enum.sum(ds) / length(ds) end)

      stage = Enum.find(stages, &(&1.name == stage_name))
      %{stage: stage, avg_days: avg_days, count: length(durations)}
    end)
    |> Enum.sort_by(& &1.stage.position)
  end

  def per_pipeline_conversion_rates(_tenant_id, pipeline_id) do
    stage_conversion_rates(pipeline_id)
  end

  def all_pipelines_conversion_rates(tenant_id) do
    pipelines = Stages.list_pipelines(tenant_id)

    Enum.flat_map(pipelines, fn pipeline ->
      stage_conversion_rates(pipeline.id)
      |> Enum.map(fn rate -> Map.put(rate, :pipeline, pipeline) end)
    end)
  end

  # Tenant-scoped analytics (all pipelines for a tenant)

  def pipeline_counts_per_stage(tenant_id, nil) do
    do_pipeline_counts_all(tenant_id)
  end

  def pipeline_counts_per_stage(_tenant_id, pipeline_id) when not is_nil(pipeline_id) do
    pipeline_counts_per_stage(pipeline_id)
  end

  def average_time_to_hire(tenant_id, nil) do
    do_average_time_to_hire(tenant_id)
  end

  def average_time_to_hire(_tenant_id, pipeline_id) when not is_nil(pipeline_id) do
    average_time_to_hire(pipeline_id)
  end

  def stage_conversion_rates(tenant_id, nil) do
    do_stage_conversion_by_type(tenant_id)
  end

  def stage_conversion_rates(_tenant_id, pipeline_id) when not is_nil(pipeline_id) do
    stage_conversion_rates(pipeline_id)
  end
end
