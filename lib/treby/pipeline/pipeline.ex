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
    Repo.delete(pipeline_stage)
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

  def get_application!(id),
    do: Repo.get!(Application, id) |> preload([:candidate, :pipeline_stage, :job])

  def create_application(attrs \\ %{}) do
    %Application{}
    |> Application.changeset(attrs)
    |> Repo.insert()
  end

  def move_application(%Application{} = application, stage_id) do
    application
    |> Application.changeset(%{pipeline_stage_id: stage_id})
    |> Repo.update()
  end
end
