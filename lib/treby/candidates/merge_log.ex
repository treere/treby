defmodule Treby.Candidates.MergeLog do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "candidate_merges" do
    field :merged_at, :utc_datetime
    field :application_mapping, :map, default: %{}
    field :thread_mapping, :map, default: %{}
    field :activity_mapping, :map, default: %{}

    belongs_to :primary_candidate, Treby.Candidates.Candidate, foreign_key: :primary_candidate_id

    belongs_to :absorbed_candidate, Treby.Candidates.Candidate,
      foreign_key: :absorbed_candidate_id

    belongs_to :tenant, Treby.Tenants.Tenant
    belongs_to :actor, Treby.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(merge_log, attrs) do
    merge_log
    |> cast(attrs, [
      :primary_candidate_id,
      :absorbed_candidate_id,
      :tenant_id,
      :actor_id,
      :merged_at,
      :application_mapping,
      :thread_mapping,
      :activity_mapping
    ])
    |> validate_required([:primary_candidate_id, :absorbed_candidate_id, :tenant_id, :merged_at])
  end
end
