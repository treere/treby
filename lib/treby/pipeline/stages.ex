defmodule Treby.Pipeline.Stages do
  @moduledoc """
  Pipeline and stage CRUD, templates, and stage role assignments.

  Extracted from `Treby.Pipeline` to keep the context focused.
  `Treby.Pipeline` remains the public facade via `defdelegate`.
  """

  import Ecto.Query, warn: false
  alias Treby.Repo
  alias Treby.Pipeline.Pipeline, as: PipelineDef
  alias Treby.Pipeline.PipelineStage
  alias Treby.Pipeline.Application
  alias Treby.Pipeline.StageExaminer
  alias Treby.Pipeline.StageReviewer
  alias Treby.Pipeline.StageAdvancer

  # Pipeline CRUD

  def list_pipelines(tenant_id) do
    PipelineDef
    |> where([p], p.tenant_id == ^tenant_id and p.is_template == false)
    |> order_by([p], p.name)
    |> Repo.all()
    |> Repo.preload(:pipeline_stages)
  end

  def list_templates(tenant_id) do
    PipelineDef
    |> where([p], p.tenant_id == ^tenant_id and p.is_template == true)
    |> order_by([p], p.name)
    |> Repo.all()
    |> Repo.preload(:pipeline_stages)
  end

  def get_pipeline!(id), do: PipelineDef |> Repo.get!(id) |> Repo.preload(:pipeline_stages)

  def get_pipeline(id), do: PipelineDef |> Repo.get(id) |> Repo.preload(:pipeline_stages)

  def create_pipeline(attrs \\ %{}) do
    case %PipelineDef{} |> PipelineDef.changeset(attrs) |> Repo.insert() do
      {:ok, pipeline} ->
        Treby.Audit.log_event("pipeline.created", "pipeline", pipeline.id, %{
          tenant_id: pipeline.tenant_id,
          metadata: %{after: %{name: pipeline.name}}
        })

        {:ok, pipeline}

      error ->
        error
    end
  end

  def update_pipeline(%PipelineDef{} = pipeline, attrs) do
    before = Map.take(pipeline, [:name, :is_default])

    case pipeline |> PipelineDef.changeset(attrs) |> Repo.update() do
      {:ok, updated} ->
        Treby.Audit.log_event("pipeline.updated", "pipeline", updated.id, %{
          tenant_id: updated.tenant_id,
          metadata: %{before: before, after: Map.take(updated, [:name, :is_default])}
        })

        {:ok, updated}

      error ->
        error
    end
  end

  def delete_pipeline(%PipelineDef{} = pipeline) do
    case Repo.delete(pipeline) do
      {:ok, deleted} ->
        Treby.Audit.log_event("pipeline.deleted", "pipeline", deleted.id, %{
          tenant_id: deleted.tenant_id,
          metadata: %{before: %{name: deleted.name}}
        })

        {:ok, deleted}

      error ->
        error
    end
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

  # Templates

  def create_template(attrs \\ %{}) do
    %PipelineDef{}
    |> PipelineDef.changeset(Map.put(attrs, :is_template, true))
    |> Repo.insert()
  end

  def delete_template(%PipelineDef{} = pipeline) do
    if pipeline.is_template do
      Repo.delete(pipeline)
    else
      {:error, :not_a_template}
    end
  end

  def clone_template_to_pipeline(%PipelineDef{} = template, new_attrs) do
    clone_pipeline(template, new_attrs)
  end

  def clone_pipeline(%PipelineDef{} = source, new_attrs) do
    {:ok, {new_pipeline, _id_map}} = clone_pipeline_with_map(source, new_attrs)
    {:ok, new_pipeline}
  end

  defp clone_pipeline_with_map(%PipelineDef{} = source, new_attrs) do
    Repo.transaction(fn ->
      {:ok, new_pipeline} =
        create_pipeline(Map.put(new_attrs, :is_template, false))

      id_map =
        source
        |> Repo.preload(:pipeline_stages)
        |> Map.fetch!(:pipeline_stages)
        |> Enum.reduce(%{}, fn stage, acc ->
          new_stage = clone_stage_with_roles(stage, new_pipeline.id)
          Map.put(acc, stage.id, new_stage.id)
        end)

      {new_pipeline, id_map}
    end)
  end

  defp clone_stage_with_roles(stage, new_pipeline_id) do
    stage =
      Repo.preload(stage, [
        :examiner_assignments,
        :reviewer_assignments,
        :advancer_assignments
      ])

    {:ok, new_stage} =
      %PipelineStage{}
      |> PipelineStage.changeset(%{
        name: stage.name,
        position: stage.position,
        color: stage.color,
        stage_type: stage.stage_type,
        min_examiners: stage.min_examiners,
        scorecard_template_id: stage.scorecard_template_id,
        pipeline_id: new_pipeline_id
      })
      |> Repo.insert()

    Enum.each(stage.examiner_assignments, fn assignment ->
      %StageExaminer{}
      |> StageExaminer.changeset(%{
        pipeline_stage_id: new_stage.id,
        user_id: assignment.user_id
      })
      |> Repo.insert!()
    end)

    Enum.each(stage.reviewer_assignments, fn assignment ->
      %StageReviewer{}
      |> StageReviewer.changeset(%{
        pipeline_stage_id: new_stage.id,
        user_id: assignment.user_id
      })
      |> Repo.insert!()
    end)

    Enum.each(stage.advancer_assignments, fn assignment ->
      %StageAdvancer{}
      |> StageAdvancer.changeset(%{
        pipeline_stage_id: new_stage.id,
        user_id: assignment.user_id
      })
      |> Repo.insert!()
    end)

    new_stage
  end

  def duplicate_pipeline(%PipelineDef{} = source_pipeline) do
    {:ok, {new_pipeline, _id_map}} =
      clone_pipeline_with_map(source_pipeline, %{
        name: "#{source_pipeline.name} (Copy)",
        tenant_id: source_pipeline.tenant_id
      })

    {:ok, new_pipeline}
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

  def job_effective_pipeline_id(%Treby.Jobs.Job{} = job) do
    job.pipeline_id || default_pipeline_id(job.tenant_id)
  end

  def job_effective_pipeline(%Treby.Jobs.Job{} = job) do
    get_pipeline!(job_effective_pipeline_id(job))
  end

  def pipeline_shared?(pipeline_id) do
    count_active_jobs(pipeline_id) > 1
  end

  def detach_job_pipeline(%Treby.Jobs.Job{} = job) do
    effective_id = job_effective_pipeline_id(job)

    transaction_result =
      Repo.transaction(fn ->
        # Serialize concurrent detaches: the share check, clone, remap and
        # repoint below execute atomically. Attaches write job rows (not the
        # pipeline row), so they may still land mid-detach — safe, because
        # detach clones instead of mutating the shared pipeline.
        PipelineDef
        |> where([p], p.id == ^effective_id)
        |> lock("FOR UPDATE")
        |> Repo.one!()

        if pipeline_shared?(effective_id) do
          source = get_pipeline!(effective_id)

          {:ok, {new_pipeline, id_map}} =
            clone_pipeline_with_map(source, %{
              name: "#{source.name} (Job)",
              tenant_id: job.tenant_id
            })

          remap_job_applications(job.id, id_map)

          {:ok, updated_job} = Treby.Jobs.update_job(job, %{pipeline_id: new_pipeline.id})
          {:ok, updated_job, new_pipeline}
        else
          {:ok, job, get_pipeline!(effective_id)}
        end
      end)

    case transaction_result do
      {:ok, result} -> result
      {:error, _} = error -> error
    end
  end

  defp remap_job_applications(job_id, id_map) when map_size(id_map) > 0 do
    Application
    |> where([a], a.job_id == ^job_id and a.pipeline_stage_id in ^Map.keys(id_map))
    |> Repo.all()
    |> Enum.each(fn app ->
      new_stage_id = Map.fetch!(id_map, app.pipeline_stage_id)
      Application.changeset(app, %{pipeline_stage_id: new_stage_id}) |> Repo.update!()
    end)

    :ok
  end

  defp remap_job_applications(_job_id, _id_map), do: :ok

  def get_pipeline_stage!(id), do: Repo.get!(PipelineStage, id)

  def create_pipeline_stage(attrs \\ %{}, actor \\ nil) do
    if actor && actor.role != "admin" do
      {:error, :unauthorized}
    else
      case %PipelineStage{} |> PipelineStage.changeset(attrs) |> Repo.insert() do
        {:ok, stage} ->
          Treby.Audit.log_event("pipeline.stage_created", "pipeline_stage", stage.id, %{
            tenant_id:
              stage.pipeline_id &&
                (Repo.get(PipelineDef, stage.pipeline_id) || %{tenant_id: nil}).tenant_id,
            actor_id: actor && actor.id,
            metadata: %{after: Map.take(stage, [:name, :position, :color, :stage_type])}
          })

          {:ok, stage}

        error ->
          error
      end
    end
  end

  def update_pipeline_stage(%PipelineStage{} = pipeline_stage, attrs, actor \\ nil) do
    if actor && actor.role != "admin" do
      {:error, :unauthorized}
    else
      before = Map.take(pipeline_stage, [:name, :position, :color, :stage_type])

      case pipeline_stage |> PipelineStage.changeset(attrs) |> Repo.update() do
        {:ok, updated} ->
          Treby.Audit.log_event("pipeline.stage_updated", "pipeline_stage", updated.id, %{
            tenant_id:
              (Repo.get(PipelineDef, updated.pipeline_id) || %{tenant_id: nil}).tenant_id,
            actor_id: actor && actor.id,
            metadata: %{
              before: before,
              after: Map.take(updated, [:name, :position, :color, :stage_type])
            }
          })

          {:ok, updated}

        error ->
          error
      end
    end
  end

  def delete_pipeline_stage(%PipelineStage{} = pipeline_stage, actor \\ nil) do
    if actor && actor.role != "admin" do
      {:error, :unauthorized}
    else
      case Repo.delete(pipeline_stage) do
        {:ok, deleted} ->
          Treby.Audit.log_event("pipeline.stage_deleted", "pipeline_stage", deleted.id, %{
            tenant_id:
              (Repo.get(PipelineDef, deleted.pipeline_id) || %{tenant_id: nil}).tenant_id,
            actor_id: actor && actor.id,
            metadata: %{before: Map.take(deleted, [:name, :position, :color])}
          })

          {:ok, deleted}

        error ->
          error
      end
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

  # Stage Role Assignments

  # Examiners

  def assign_examiner(%PipelineStage{} = stage, user_id) do
    %StageExaminer{}
    |> StageExaminer.changeset(%{pipeline_stage_id: stage.id, user_id: user_id})
    |> Repo.insert(on_conflict: :nothing)
  end

  def remove_examiner(%PipelineStage{} = stage, user_id) do
    StageExaminer
    |> where([se], se.pipeline_stage_id == ^stage.id and se.user_id == ^user_id)
    |> Repo.delete_all()
  end

  def list_examiners(%PipelineStage{} = stage) do
    StageExaminer
    |> where([se], se.pipeline_stage_id == ^stage.id)
    |> preload(:user)
    |> Repo.all()
  end

  def list_examiner_ids(%PipelineStage{} = stage) do
    StageExaminer
    |> where([se], se.pipeline_stage_id == ^stage.id)
    |> select([se], se.user_id)
    |> Repo.all()
  end

  # Reviewers

  def assign_reviewer(%PipelineStage{} = stage, user_id) do
    %StageReviewer{}
    |> StageReviewer.changeset(%{pipeline_stage_id: stage.id, user_id: user_id})
    |> Repo.insert(on_conflict: :nothing)
  end

  def remove_reviewer(%PipelineStage{} = stage, user_id) do
    StageReviewer
    |> where([sr], sr.pipeline_stage_id == ^stage.id and sr.user_id == ^user_id)
    |> Repo.delete_all()
  end

  def list_reviewers(%PipelineStage{} = stage) do
    StageReviewer
    |> where([sr], sr.pipeline_stage_id == ^stage.id)
    |> preload(:user)
    |> Repo.all()
  end

  def list_reviewer_ids(%PipelineStage{} = stage) do
    StageReviewer
    |> where([sr], sr.pipeline_stage_id == ^stage.id)
    |> select([sr], sr.user_id)
    |> Repo.all()
  end

  # Advancers

  def assign_advancer(%PipelineStage{} = stage, user_id) do
    %StageAdvancer{}
    |> StageAdvancer.changeset(%{pipeline_stage_id: stage.id, user_id: user_id})
    |> Repo.insert(on_conflict: :nothing)
  end

  def remove_advancer(%PipelineStage{} = stage, user_id) do
    StageAdvancer
    |> where([sa], sa.pipeline_stage_id == ^stage.id and sa.user_id == ^user_id)
    |> Repo.delete_all()
  end

  def list_advancers(%PipelineStage{} = stage) do
    StageAdvancer
    |> where([sa], sa.pipeline_stage_id == ^stage.id)
    |> preload(:user)
    |> Repo.all()
  end

  def list_advancer_ids(%PipelineStage{} = stage) do
    StageAdvancer
    |> where([sa], sa.pipeline_stage_id == ^stage.id)
    |> select([sa], sa.user_id)
    |> Repo.all()
  end

  def user_is_advancer?(%PipelineStage{} = stage, user_id) do
    StageAdvancer
    |> where([sa], sa.pipeline_stage_id == ^stage.id and sa.user_id == ^user_id)
    |> Repo.exists?()
  end

  # Eligible examiners for a pipeline stage

  def list_eligible_examiners(%PipelineStage{} = stage) do
    examiner_ids = list_examiner_ids(stage)

    if examiner_ids == [] do
      []
    else
      rule_ids =
        Treby.Availability.AvailabilityRule
        |> where([r], r.user_id in ^examiner_ids)
        |> select([r], r.user_id)
        |> Repo.all()
        |> MapSet.new()

      list_examiners(stage)
      |> Enum.filter(fn se -> MapSet.member?(rule_ids, se.user_id) end)
    end
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
      %{name: "Hired", position: 5, color: "#22c55e", stage_type: "hired"},
      %{name: "Rejected", position: 6, color: "#ef4444", stage_type: "rejected"}
    ]

    Enum.each(default_stages, fn stage_attrs ->
      %PipelineStage{}
      |> PipelineStage.changeset(Map.put(stage_attrs, :pipeline_id, pipeline.id))
      |> Repo.insert!()
    end)

    pipeline
  end
end
