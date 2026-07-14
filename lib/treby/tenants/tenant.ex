defmodule Treby.Tenants.Tenant do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "tenants" do
    field :name, :string
    field :slug, :string
    field :settings, :map, default: %{}

    has_many :users, Treby.Accounts.User
    has_many :jobs, Treby.Jobs.Job
    has_many :candidates, Treby.Candidates.Candidate
    has_many :applications, Treby.Pipeline.Application

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(tenant, attrs) do
    tenant
    |> cast(attrs, [:name, :slug, :settings])
    |> validate_required([:name, :slug])
    |> unique_constraint(:slug)
    |> validate_format(:slug, ~r/^[a-z0-9-]+$/,
      message: "must contain only lowercase letters, numbers, and hyphens"
    )
  end
end
