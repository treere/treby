defmodule Treby.CandidatePortal.CandidateOtp do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "candidate_otps" do
    field :code, :string
    field :expires_at, :utc_datetime
    field :attempts, :integer, default: 0
    field :used_at, :utc_datetime

    belongs_to :candidate, Treby.Candidates.Candidate
    belongs_to :tenant, Treby.Tenants.Tenant

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(otp, attrs) do
    otp
    |> cast(attrs, [:code, :expires_at, :attempts, :used_at, :candidate_id, :tenant_id])
    |> validate_required([:code, :expires_at, :candidate_id, :tenant_id])
  end
end
