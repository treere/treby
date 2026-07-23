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

  def create_pipeline_stage(attrs \\ %{}) do
    %PipelineStage{}
    |> PipelineStage.changeset(attrs)
    |> Repo.insert()
  end

  def update_pipeline_stage(%PipelineStage{} = pipeline_stage, attrs) do
    pipeline_stage
    |> PipelineStage.changeset(attrs)
    |> Repo.update()
  end

  def delete_pipeline_stage(%PipelineStage{} = pipeline_stage) do
    Repo.delete(pipeline_stage)
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

  def get_application!(id),
    do: Repo.get!(Application, id) |> Repo.preload([:candidate, :pipeline_stage, :job])

  def get_application!(tenant_id, id) do
    Application
    |> where([a], a.tenant_id == ^tenant_id and a.id == ^id)
    |> preload([:candidate, :pipeline_stage, :job])
    |> Repo.one!()
  end

  def create_application(attrs \\ %{}) do
    %Application{}
    |> Application.changeset(attrs)
    |> Repo.insert()
  end

  def move_application(%Application{} = application, stage_id) do
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
end
