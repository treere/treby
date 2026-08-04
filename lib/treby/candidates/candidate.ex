defmodule Treby.Candidates.Candidate do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "candidates" do
    field :name, :string
    field :email, :string
    field :phone, :string
    field :linkedin_url, :string
    field :custom_fields, :map, default: %{}
    field :merged_at, :utc_datetime

    belongs_to :tenant, Treby.Tenants.Tenant
    has_many :applications, Treby.Pipeline.Application

    belongs_to :merged_into, Treby.Candidates.Candidate, foreign_key: :merged_into_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(candidate, attrs) do
    candidate
    |> cast(attrs, [:name, :email, :phone, :linkedin_url, :custom_fields])
    |> validate_required([:name, :email])
    |> validate_format(:email, ~r/@/)
  end
end
