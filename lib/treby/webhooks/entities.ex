defmodule Treby.Webhooks.Entities do
  @moduledoc """
  Registry mapping audit `entity_type` strings to their Ecto schema modules,
  with a shallow (no nested associations), PII-safe fetch used to build
  webhook payloads.
  """

  import Ecto.Query, warn: false
  alias Treby.Repo

  @registry %{
    "candidate" => Treby.Candidates.Candidate,
    "application" => Treby.Pipeline.Application,
    "pipeline" => Treby.Pipeline.Pipeline,
    "pipeline_stage" => Treby.Pipeline.PipelineStage,
    "note" => Treby.Notes.Note,
    "scorecard_template" => Treby.Scorecards.ScorecardTemplate,
    "scorecard" => Treby.Scorecards.Scorecard,
    "interview_event" => Treby.Interviews.InterviewEvent,
    "message" => Treby.CandidatePortal.Message,
    "custom_field" => Treby.Customization.CustomField,
    "tenant" => Treby.Tenants.Tenant,
    "job" => Treby.Jobs.Job,
    "membership" => Treby.Memberships.Membership,
    "invite" => Treby.Invites.Invite,
    "ai_tool_run" => Treby.AI.ToolRun
  }

  @doc """
  Fetch the current entity for a webhook payload.

  Returns:
    - `{:ok, sanitized_map}` when found
    - `{:not_found, nil}` when the entity no longer exists (e.g. a delete event)
    - `{:unknown, nil}` when the entity_type is not in the registry
  """
  def fetch(entity_type, entity_id) do
    case Map.get(@registry, entity_type) do
      nil ->
        {:unknown, nil}

      schema ->
        case Repo.get(schema, entity_id) do
          nil -> {:not_found, nil}
          struct -> {:ok, shallow(struct)}
        end
    end
  end

  defp shallow(struct) do
    schema = struct.__struct__
    fields = schema.__schema__(:fields)

    fields
    |> Enum.map(fn field -> {field, Map.get(struct, field)} end)
    |> Map.new()
    |> Treby.Audit.sanitize_metadata("webhook")
  end
end
