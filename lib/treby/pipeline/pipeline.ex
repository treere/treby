defmodule Treby.Pipeline do
  @moduledoc """
  The Pipeline context.
  """

  import Ecto.Query, warn: false
  alias Treby.Repo
  alias Treby.Pipeline.Pipeline, as: PipelineDef
  alias Treby.Pipeline.PipelineStage
  alias Treby.Pipeline.Application

  # Pipeline CRUD

  def list_pipelines(tenant_id) do
    PipelineDef
    |> where([p], p.tenant_id == ^tenant_id)
    |> order_by([p], p.name)
    |> Repo.all()
    |> Repo.preload(:pipeline_stages)
  end

  def get_pipeline!(id), do: PipelineDef |> Repo.get!(id) |> Repo.preload(:pipeline_stages)

  def create_pipeline(attrs \\ %{}) do
    %PipelineDef{}
    |> PipelineDef.changeset(attrs)
    |> Repo.insert()
  end

  def update_pipeline(%PipelineDef{} = pipeline, attrs) do
    pipeline
    |> PipelineDef.changeset(attrs)
    |> Repo.update()
  end

  def delete_pipeline(%PipelineDef{} = pipeline) do
    Repo.delete(pipeline)
  end

  def set_default_pipeline(%PipelineDef{} = pipeline) do
    Repo.transaction(fn ->
      # Unset current default
      from(p in PipelineDef,
        where: p.tenant_id == ^pipeline.tenant_id and p.is_default == true,
        update: [set: [is_default: false]]
      )
      |> Repo.update_all([])

      # Set new default
      pipeline
      |> PipelineDef.changeset(%{is_default: true})
      |> Repo.update!()
    end)
  end

  def duplicate_pipeline(%PipelineDef{} = source_pipeline) do
    Repo.transaction(fn ->
      {:ok, new_pipeline} =
        create_pipeline(%{
          name: "#{source_pipeline.name} (Copy)",
          tenant_id: source_pipeline.tenant_id
        })

      source_stages = Repo.preload(source_pipeline, :pipeline_stages).pipeline_stages

      Enum.each(source_stages, fn stage ->
        %PipelineStage{}
        |> PipelineStage.changeset(%{
          name: stage.name,
          position: stage.position,
          color: stage.color,
          stage_type: stage.stage_type,
          pipeline_id: new_pipeline.id
        })
        |> Repo.insert!()
      end)

      new_pipeline
    end)
  end

  def default_pipeline_id(tenant_id) do
    PipelineDef
    |> where([p], p.tenant_id == ^tenant_id and p.is_default == true)
    |> select([p], p.id)
    |> Repo.one()
  end

  def count_active_jobs(pipeline_id) do
    Treby.Jobs.Job
    |> where([j], j.pipeline_id == ^pipeline_id)
    |> select([j], count(j.id))
    |> Repo.one()
  end

  def count_pipeline_stages(pipeline_id) do
    PipelineStage
    |> where([ps], ps.pipeline_id == ^pipeline_id)
    |> select([ps], count(ps.id))
    |> Repo.one()
  end

  # Pipeline Stages (per-pipeline)

  def list_pipeline_stages(pipeline_id) do
    PipelineStage
    |> where([ps], ps.pipeline_id == ^pipeline_id)
    |> order_by([ps], ps.position)
    |> Repo.all()
  end

  def list_pipeline_stages_for_job(job_id) do
    job = Repo.get!(Treby.Jobs.Job, job_id)
    pipeline_id = job.pipeline_id || default_pipeline_id(job.tenant_id)

    PipelineStage
    |> where([ps], ps.pipeline_id == ^pipeline_id)
    |> order_by([ps], ps.position)
    |> Repo.all()
  end

  def get_pipeline_stage!(id), do: Repo.get!(PipelineStage, id)

  def create_pipeline_stage(attrs \\ %{}, actor \\ nil) do
    if actor && actor.role != "admin" do
      {:error, :unauthorized}
    else
      %PipelineStage{}
      |> PipelineStage.changeset(attrs)
      |> Repo.insert()
    end
  end

  def update_pipeline_stage(%PipelineStage{} = pipeline_stage, attrs, actor \\ nil) do
    if actor && actor.role != "admin" do
      {:error, :unauthorized}
    else
      pipeline_stage
      |> PipelineStage.changeset(attrs)
      |> Repo.update()
    end
  end

  def delete_pipeline_stage(%PipelineStage{} = pipeline_stage, actor \\ nil) do
    if actor && actor.role != "admin" do
      {:error, :unauthorized}
    else
      Repo.delete(pipeline_stage)
    end
  end

  def reassign_and_delete_stage(%PipelineStage{} = stage, target_stage_id) do
    Repo.transaction(fn ->
      # Move all applications from this stage to target
      from(a in Application,
        where: a.pipeline_stage_id == ^stage.id,
        update: [set: [pipeline_stage_id: ^target_stage_id]]
      )
      |> Repo.update_all([])

      # Delete the stage
      Repo.delete!(stage)
    end)
  end

  def active_applications_count(stage_id) do
    Application
    |> where([a], a.pipeline_stage_id == ^stage_id)
    |> select([a], count(a.id))
    |> Repo.one()
  end

  def delete_pipeline_with_reassignment(%PipelineDef{} = pipeline) do
    default_id = default_pipeline_id(pipeline.tenant_id)

    if pipeline.id == default_id do
      {:error, :cannot_delete_default}
    else
      Repo.transaction(fn ->
        # Move all jobs using this pipeline to the default
        from(j in Treby.Jobs.Job,
          where: j.pipeline_id == ^pipeline.id,
          update: [set: [pipeline_id: ^default_id]]
        )
        |> Repo.update_all([])

        # Delete the pipeline (cascades to stages)
        Repo.delete!(pipeline)
      end)

      :ok
    end
  end

  def change_pipeline_stage(%PipelineStage{} = pipeline_stage, attrs \\ %{}) do
    PipelineStage.changeset(pipeline_stage, attrs)
  end

  def change_pipeline(%PipelineDef{} = pipeline, attrs \\ %{}) do
    PipelineDef.changeset(pipeline, attrs)
  end

  # Legacy: create default stages for a pipeline (used in migration/seeds)

  def create_default_pipeline_stages(tenant) do
    {:ok, pipeline} =
      create_pipeline(%{
        name: "Default",
        tenant_id: tenant.id,
        is_default: true
      })

    default_stages = [
      %{name: "New", position: 0, color: "#10b981", stage_type: "new"},
      %{name: "Screen", position: 1, color: "#3b82f6"},
      %{name: "Phone Screen", position: 2, color: "#8b5cf6"},
      %{name: "Interview", position: 3, color: "#f59e0b", stage_type: "interview"},
      %{name: "Offer", position: 4, color: "#ec4899", stage_type: "offer"},
      %{name: "Hired", position: 5, color: "#22c55e", stage_type: "hired"}
    ]

    Enum.each(default_stages, fn stage_attrs ->
      %PipelineStage{}
      |> PipelineStage.changeset(Map.put(stage_attrs, :pipeline_id, pipeline.id))
      |> Repo.insert!()
    end)

    pipeline
  end

  # Applications

  def list_applications_for_job(job_id) do
    Application
    |> where([a], a.job_id == ^job_id)
    |> preload([:candidate, :pipeline_stage])
    |> Repo.all()
  end

  def list_applications_for_candidate(tenant_id, candidate_id) do
    Application
    |> where([a], a.tenant_id == ^tenant_id and a.candidate_id == ^candidate_id)
    |> preload([:job, :pipeline_stage])
    |> Repo.all()
  end

  def list_applications_by_stage(job_id) do
    stages = list_pipeline_stages_for_job(job_id)

    applications =
      Application
      |> where([a], a.job_id == ^job_id)
      |> preload([:candidate])
      |> Repo.all()

    Enum.group_by(applications, & &1.pipeline_stage_id)
    |> then(fn grouped ->
      Enum.map(stages, fn stage ->
        {stage, Map.get(grouped, stage.id, [])}
      end)
    end)
  end

  def candidate_application_counts(tenant_id, candidate_ids) do
    if candidate_ids == [] do
      %{}
    else
      Application
      |> where([a], a.tenant_id == ^tenant_id and a.candidate_id in ^candidate_ids)
      |> group_by([a], a.candidate_id)
      |> select([a], %{candidate_id: a.candidate_id, count: count(a.id)})
      |> Repo.all()
      |> Map.new(fn %{candidate_id: cid, count: n} -> {cid, n} end)
    end
  end

  def get_application!(id),
    do: Repo.get!(Application, id) |> Repo.preload([:candidate, :pipeline_stage, :job])

  def get_application!(tenant_id, id) do
    Application
    |> where([a], a.tenant_id == ^tenant_id and a.id == ^id)
    |> preload([:candidate, :pipeline_stage, :job])
    |> Repo.one!()
  end

  def create_application(attrs \\ %{}) do
    attrs
    |> stringify_keys()
    |> ensure_anagrafica()
    |> set_duplicate_flag()
    |> then(fn attrs ->
      %Application{}
      |> Application.changeset(attrs)
      |> Repo.insert()
    end)
  end

  defp stringify_keys(attrs) do
    Map.new(attrs, fn {key, value} -> {to_string(key), value} end)
  end

  def build_anagrafica(%Treby.Candidates.Candidate{} = candidate) do
    %{
      "name" => candidate.name,
      "email" => candidate.email,
      "phone" => candidate.phone,
      "linkedin_url" => candidate.linkedin_url
    }
    |> Enum.reject(fn {_k, v} -> is_nil(v) || v == "" end)
    |> Map.new()
  end

  defp ensure_anagrafica(attrs) do
    if Map.get(attrs, "anagrafica") || Map.get(attrs, :anagrafica) do
      attrs
    else
      case Map.get(attrs, "candidate_id") || Map.get(attrs, :candidate_id) do
        nil ->
          attrs

        candidate_id ->
          case Repo.get(Treby.Candidates.Candidate, candidate_id) do
            nil -> attrs
            candidate -> Map.put(attrs, "anagrafica", build_anagrafica(candidate))
          end
      end
    end
  end

  defp set_duplicate_flag(attrs) do
    candidate_id = Map.get(attrs, "candidate_id") || Map.get(attrs, :candidate_id)
    job_id = Map.get(attrs, "job_id") || Map.get(attrs, :job_id)

    if candidate_id && job_id do
      is_duplicate? =
        Application
        |> where([a], a.candidate_id == ^candidate_id and a.job_id == ^job_id)
        |> Repo.exists?()

      attrs |> Map.put("is_duplicate", is_duplicate?)
    else
      attrs
    end
  end

  def recompute_duplicate_flags(candidate_id) do
    applications =
      Application
      |> where([a], a.candidate_id == ^candidate_id)
      |> order_by([a], asc: a.inserted_at, asc: a.id)
      |> Repo.all()

    duplicate_ids =
      applications
      |> Enum.group_by(& &1.job_id)
      |> Enum.flat_map(fn {_job_id, job_apps} -> Enum.drop(job_apps, 1) end)
      |> Enum.map(& &1.id)

    from(a in Application, where: a.candidate_id == ^candidate_id)
    |> Repo.update_all(set: [is_duplicate: false])

    if duplicate_ids != [] do
      from(a in Application, where: a.id in ^duplicate_ids)
      |> Repo.update_all(set: [is_duplicate: true])
    end

    :ok
  end

  def move_application(%Application{} = application, stage_id, opts \\ []) do
    old_stage_id = application.pipeline_stage_id

    result =
      application
      |> Application.changeset(%{pipeline_stage_id: stage_id})
      |> Repo.update()

    case result do
      {:ok, app} ->
        Phoenix.PubSub.broadcast(
          Treby.PubSub,
          "pipeline:#{app.job_id}",
          {:pipeline_updated, app.job_id}
        )

        # Log the stage change
        old_stage = if old_stage_id, do: get_pipeline_stage!(old_stage_id)
        new_stage = get_pipeline_stage!(stage_id)

        Treby.Activities.log_event(
          "application_stage_changed",
          "application",
          app.id,
          %{
            old_stage: old_stage && old_stage.name,
            new_stage: new_stage && new_stage.name,
            tenant_id: app.tenant_id
          }
        )

        # Send stage change notification email if not skipped (non-blocking)
        unless opts[:skip_notification] do
          try do
            Treby.Notifications.notify_stage_change(app, opts[:actor])
          rescue
            _ -> :ok
          catch
            _ -> :ok
          end
        end

        {:ok, app}

      error ->
        error
    end
  end

  def subscribe_to_pipeline(job_id) do
    Phoenix.PubSub.subscribe(Treby.PubSub, "pipeline:#{job_id}")
  end

  # Review state

  def mark_reviewed(%Application{} = application) do
    application
    |> Application.changeset(%{reviewed: true})
    |> Repo.update()
  end

  def mark_unreviewed(%Application{} = application) do
    application
    |> Application.changeset(%{reviewed: false})
    |> Repo.update()
  end

  def toggle_reviewed(%Application{} = application) do
    application
    |> Application.changeset(%{reviewed: not application.reviewed})
    |> Repo.update()
  end

  # Analytics queries

  def pipeline_counts_per_stage(nil) do
    PipelineStage
    |> order_by([ps], ps.position)
    |> Repo.all()
    |> Enum.group_by(& &1.name)
    |> Enum.map(fn {_name, stages} ->
      count =
        Enum.reduce(stages, 0, fn stage, acc ->
          stage_count =
            Application
            |> where([a], a.pipeline_stage_id == ^stage.id)
            |> select([a], count(a.id))
            |> Repo.one()

          acc + stage_count
        end)

      %{stage: List.first(stages), count: count}
    end)
    |> Enum.sort_by(& &1.stage.position)
  end

  def pipeline_counts_per_stage(pipeline_id) do
    PipelineStage
    |> where([ps], ps.pipeline_id == ^pipeline_id)
    |> order_by([ps], ps.position)
    |> Repo.all()
    |> Enum.map(fn stage ->
      count =
        Application
        |> where([a], a.pipeline_stage_id == ^stage.id)
        |> select([a], count(a.id))
        |> Repo.one()

      %{stage: stage, count: count}
    end)
  end

  def pipeline_counts_per_stage_for_job(job_id) do
    stages = list_pipeline_stages_for_job(job_id)

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

  def average_time_to_hire(nil) do
    hired_stages =
      PipelineStage
      |> where([ps], ps.stage_type == "hired")
      |> select([ps], ps.id)
      |> Repo.all()

    case hired_stages do
      [] ->
        nil

      stage_ids ->
        Application
        |> where([a], a.pipeline_stage_id in ^stage_ids)
        |> select([a], avg(fragment("EXTRACT(DAY FROM (? - ?))", a.updated_at, a.inserted_at)))
        |> Repo.one()
    end
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

  def stage_conversion_rates(nil) do
    stage_type_order = ["new", "interview", "offer", "hired"]

    stages_by_type =
      PipelineStage
      |> where([ps], not is_nil(ps.stage_type))
      |> Repo.all()
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
          |> select([a], count(a.id))
          |> Repo.one()
        end

      to_count =
        if to_stage_ids == [] do
          0
        else
          Application
          |> where([a], a.pipeline_stage_id in ^to_stage_ids)
          |> select([a], count(a.id))
          |> Repo.one()
        end

      from_stage = %{name: String.capitalize(from_type), color: "#6B7280", id: from_type}
      to_stage = %{name: String.capitalize(to_type), color: "#6B7280", id: to_type}
      rate = if from_count > 0, do: round(to_count / from_count * 100), else: 0

      [%{from: from_stage, to: to_stage, rate: rate}]
    end)
  end

  def stage_conversion_rates(pipeline_id) do
    stages = list_pipeline_stages(pipeline_id)

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
    stages = list_pipeline_stages(pipeline_id)

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

    events =
      ActivityLog
      |> where(
        [a],
        a.action == "application_stage_changed" and
          a.entity_type == "application" and
          a.entity_id in ^application_ids
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
    pipelines = list_pipelines(tenant_id)

    Enum.flat_map(pipelines, fn pipeline ->
      stage_conversion_rates(pipeline.id)
      |> Enum.map(fn rate -> Map.put(rate, :pipeline, pipeline) end)
    end)
  end

  def source_breakdown(nil) do
    Application
    |> select([a], %{source: fragment("COALESCE(?, 'Unknown')", a.source), count: count(a.id)})
    |> group_by([a], fragment("COALESCE(?, 'Unknown')", a.source))
    |> order_by([a], desc: count(a.id))
    |> Repo.all()
  end

  def source_breakdown(pipeline_id) do
    Application
    |> where([a], a.pipeline_id == ^pipeline_id)
    |> select([a], %{source: fragment("COALESCE(?, 'Unknown')", a.source), count: count(a.id)})
    |> group_by([a], fragment("COALESCE(?, 'Unknown')", a.source))
    |> order_by([a], desc: count(a.id))
    |> Repo.all()
  end
end
