defmodule Treby.Pipeline do
  @moduledoc """
  The Pipeline context facade.

  Delegates to focused submodules:
  - `Treby.Pipeline.Stages` for pipelines, stages, and role assignments
  - `Treby.Pipeline.Applications` for applications and progress
  - `Treby.Pipeline.Analytics` for analytics queries
  """

  alias Treby.Pipeline.Analytics
  alias Treby.Pipeline.Applications
  alias Treby.Pipeline.Stages
  alias Treby.Pipeline.Pipeline, as: PipelineDef
  alias Treby.Pipeline.PipelineStage
  alias Treby.Pipeline.Application

  # Stages

  defdelegate list_pipelines(tenant_id), to: Stages
  defdelegate get_pipeline!(id), to: Stages
  defdelegate get_pipeline(id), to: Stages
  defdelegate create_pipeline(attrs \\ %{}), to: Stages
  defdelegate update_pipeline(pipeline, attrs), to: Stages
  defdelegate delete_pipeline(pipeline), to: Stages
  defdelegate set_default_pipeline(pipeline), to: Stages
  defdelegate clone_pipeline(source, new_attrs), to: Stages
  defdelegate duplicate_pipeline(source_pipeline), to: Stages
  defdelegate default_pipeline_id(tenant_id), to: Stages
  defdelegate count_active_jobs(pipeline_id), to: Stages
  defdelegate count_pipeline_stages(pipeline_id), to: Stages
  defdelegate list_pipeline_stages(pipeline_id), to: Stages
  defdelegate list_pipeline_stages_for_job(job_id), to: Stages
  defdelegate job_effective_pipeline_id(job), to: Stages
  defdelegate job_effective_pipeline(job), to: Stages
  defdelegate pipeline_shared?(pipeline_id), to: Stages
  defdelegate detach_job_pipeline(job), to: Stages
  defdelegate get_pipeline_stage!(id), to: Stages
  defdelegate create_pipeline_stage(attrs \\ %{}, actor \\ nil), to: Stages
  defdelegate update_pipeline_stage(pipeline_stage, attrs, actor \\ nil), to: Stages
  defdelegate delete_pipeline_stage(pipeline_stage, actor \\ nil), to: Stages
  defdelegate reassign_and_delete_stage(stage, target_stage_id), to: Stages
  defdelegate active_applications_count(stage_id), to: Stages
  defdelegate delete_pipeline_with_reassignment(pipeline), to: Stages
  defdelegate change_pipeline_stage(pipeline_stage, attrs \\ %{}), to: Stages
  defdelegate change_pipeline(pipeline, attrs \\ %{}), to: Stages
  defdelegate assign_examiner(stage, user_id), to: Stages
  defdelegate remove_examiner(stage, user_id), to: Stages
  defdelegate list_examiners(stage), to: Stages
  defdelegate list_examiner_ids(stage), to: Stages
  defdelegate assign_reviewer(stage, user_id), to: Stages
  defdelegate remove_reviewer(stage, user_id), to: Stages
  defdelegate list_reviewers(stage), to: Stages
  defdelegate list_reviewer_ids(stage), to: Stages
  defdelegate assign_advancer(stage, user_id), to: Stages
  defdelegate remove_advancer(stage, user_id), to: Stages
  defdelegate list_advancers(stage), to: Stages
  defdelegate list_advancer_ids(stage), to: Stages
  defdelegate user_is_advancer?(stage, user_id), to: Stages
  defdelegate list_eligible_examiners(stage), to: Stages
  defdelegate create_default_pipeline_stages(tenant), to: Stages

  # Applications

  defdelegate all_scorecards_completed?(application), to: Applications
  defdelegate ready_to_advance?(application), to: Applications
  defdelegate interview_completed?(application), to: Applications
  defdelegate current_state(application), to: Applications
  defdelegate list_applications_for_job(job_id, opts \\ []), to: Applications
  defdelegate list_applications_for_candidate(tenant_id, candidate_id), to: Applications
  defdelegate list_applications_by_stage(job_id, opts \\ []), to: Applications
  defdelegate candidate_application_counts(tenant_id, candidate_ids), to: Applications
  defdelegate other_positions_text(counts, candidate_id), to: Applications
  defdelegate get_application!(id), to: Applications
  defdelegate get_application(id), to: Applications
  defdelegate get_application!(tenant_id, id), to: Applications
  defdelegate get_application_for_candidate!(tenant_id, candidate_id, id), to: Applications
  defdelegate get_application_for_candidate(tenant_id, candidate_id, id), to: Applications
  defdelegate create_application(attrs \\ %{}, opts \\ []), to: Applications
  defdelegate build_anagrafica(candidate), to: Applications
  defdelegate recompute_duplicate_flags(candidate_id), to: Applications
  defdelegate move_application(application, stage_id, opts \\ []), to: Applications
  defdelegate subscribe_to_pipeline(job_id), to: Applications
  defdelegate mark_reviewed(application), to: Applications
  defdelegate mark_unreviewed(application), to: Applications
  defdelegate toggle_reviewed(application), to: Applications

  # Analytics

  defdelegate pipeline_counts_per_stage(arg), to: Analytics
  defdelegate pipeline_counts_per_stage(tenant_id, pipeline_id), to: Analytics
  defdelegate pipeline_counts_per_stage_for_job(job_id), to: Analytics
  defdelegate average_time_to_hire(arg), to: Analytics
  defdelegate average_time_to_hire(tenant_id, pipeline_id), to: Analytics
  defdelegate stage_conversion_rates(arg), to: Analytics
  defdelegate stage_conversion_rates(tenant_id, pipeline_id), to: Analytics
  defdelegate time_in_stage_metrics(tenant_id, pipeline_id), to: Analytics
  defdelegate per_pipeline_conversion_rates(tenant_id, pipeline_id), to: Analytics
  defdelegate all_pipelines_conversion_rates(tenant_id), to: Analytics
  defdelegate source_breakdown(arg), to: Analytics
  defdelegate source_breakdown(tenant_id, pipeline_id), to: Analytics

  # Keep schema aliases available for callers that rely on them transitively.
  # Unused aliases are intentional for documentation; silence warnings.
  @doc false
  def __facade_schemas__ do
    {PipelineDef, PipelineStage, Application}
  end
end
