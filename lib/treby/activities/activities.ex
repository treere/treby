defmodule Treby.Activities do
  @moduledoc """
  The Activities context — provides activity logging for hiring actions.
  """

  import Ecto.Query, warn: false
  alias Treby.Repo
  alias Treby.Activities.ActivityLog

  @doc """
  Log an activity event.

  ## Options

    * `:actor_id` — the user who performed the action (optional)
    * `:tenant_id` — the tenant (required)

  ## Examples

      log_event("application_stage_changed", "application", app_id, %{
        old_stage: "Screen",
        new_stage: "Interview",
        actor_id: user.id,
        tenant_id: tenant.id
      })
  """
  def log_event(action, entity_type, entity_id, metadata \\ %{}) do
    %ActivityLog{}
    |> ActivityLog.changeset(%{
      action: action,
      entity_type: entity_type,
      entity_id: entity_id,
      actor_id: metadata[:actor_id],
      tenant_id: metadata[:tenant_id],
      metadata: Map.drop(metadata, [:actor_id, :tenant_id])
    })
    |> Repo.insert()
  end

  @doc """
  List activity events for a given entity, most recent first.
  """
  def list_events_for_entity(entity_type, entity_id, limit \\ 20) do
    ActivityLog
    |> where([a], a.entity_type == ^entity_type and a.entity_id == ^entity_id)
    |> order_by([a], desc: a.inserted_at)
    |> limit(^limit)
    |> preload([:actor])
    |> Repo.all()
  end
end
