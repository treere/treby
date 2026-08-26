defmodule Treby.CandidatePortal.CandidateToken do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "candidate_tokens" do
    field :token, :string
    field :used_at, :utc_datetime
    field :expires_at, :utc_datetime

    belongs_to :candidate, Treby.Candidates.Candidate
    belongs_to :tenant, Treby.Tenants.Tenant

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(token, attrs) do
    token
    |> cast(attrs, [:token, :used_at, :expires_at, :candidate_id, :tenant_id])
    |> validate_required([:token, :expires_at, :candidate_id, :tenant_id])
  end
end
