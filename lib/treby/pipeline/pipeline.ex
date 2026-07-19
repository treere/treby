defmodule Treby.Pipeline do
  @moduledoc """
  The Pipeline context.
  """

  import Ecto.Query, warn: false
  alias Treby.Repo
  alias Treby.Pipeline.PipelineStage
  alias Treby.Pipeline.Application

  def list_pipeline_stages(tenant_id) do
    PipelineStage
    |> where([ps], ps.tenant_id == ^tenant_id)
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
    if has_active_applications?(pipeline_stage.id) do
      {:error, :has_active_applications}
    else
      Repo.delete(pipeline_stage)
    end
  end

  defp has_active_applications?(stage_id) do
    Application
    |> where([a], a.pipeline_stage_id == ^stage_id)
    |> select([a], count(a.id))
    |> Repo.one()
    |> Kernel.>(0)
  end

  def change_pipeline_stage(%PipelineStage{} = pipeline_stage, attrs \\ %{}) do
    PipelineStage.changeset(pipeline_stage, attrs)
  end

  def create_default_pipeline_stages(tenant) do
    default_stages = [
      %{name: "New", position: 0, color: "#10b981"},
      %{name: "Screen", position: 1, color: "#3b82f6"},
      %{name: "Phone Screen", position: 2, color: "#8b5cf6"},
      %{name: "Interview", position: 3, color: "#f59e0b"},
      %{name: "Offer", position: 4, color: "#ec4899"},
      %{name: "Hired", position: 5, color: "#22c55e"}
    ]

    Enum.each(default_stages, fn stage_attrs ->
      %PipelineStage{}
      |> PipelineStage.changeset(Map.put(stage_attrs, :tenant_id, tenant.id))
      |> Repo.insert!()
    end)
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

  defp list_pipeline_stages_for_job(job_id) do
    job = Treby.Repo.get!(Treby.Jobs.Job, job_id)

    PipelineStage
    |> where([ps], ps.tenant_id == ^job.tenant_id)
    |> order_by([ps], ps.position)
    |> Repo.all()
  end

  # Analytics queries

  def pipeline_counts_per_stage(tenant_id) do
    PipelineStage
    |> where([ps], ps.tenant_id == ^tenant_id)
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

  def average_time_to_hire(tenant_id) do
    hired_stage =
      PipelineStage
      |> where([ps], ps.tenant_id == ^tenant_id and ps.name == "Hired")
      |> Repo.one()

    case hired_stage do
      nil ->
        nil

      stage ->
        Application
        |> where([a], a.tenant_id == ^tenant_id and a.pipeline_stage_id == ^stage.id)
        |> select([a], avg(fragment("EXTRACT(DAY FROM (? - ?))", a.updated_at, a.inserted_at)))
        |> Repo.one()
    end
  end

  def stage_conversion_rates(tenant_id) do
    stages = list_pipeline_stages(tenant_id)

    stages
    |> Enum.chunk_every(2, 1, :discard)
    |> Enum.flat_map(fn [from_stage, to_stage] ->
      from_count =
        Application
        |> where([a], a.tenant_id == ^tenant_id and a.pipeline_stage_id == ^from_stage.id)
        |> select([a], count(a.id))
        |> Repo.one()

      to_count =
        Application
        |> where([a], a.tenant_id == ^tenant_id and a.pipeline_stage_id == ^to_stage.id)
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

  def get_application!(id),
    do: Repo.get!(Application, id) |> preload([:candidate, :pipeline_stage, :job])

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

        {:ok, app}

      error ->
        error
    end
  end

  def subscribe_to_pipeline(job_id) do
    Phoenix.PubSub.subscribe(Treby.PubSub, "pipeline:#{job_id}")
  end
end
