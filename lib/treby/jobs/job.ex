defmodule Treby.Jobs.Job do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "jobs" do
    field :title, :string
    field :description, :string
    field :salary_range, :string
    field :status, :string, default: "open"
    field :custom_fields, :map, default: %{}

    belongs_to :tenant, Treby.Tenants.Tenant
    belongs_to :pipeline, Treby.Pipeline.Pipeline

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(job, attrs) do
    job
    |> cast(attrs, [:title, :description, :salary_range, :status, :custom_fields, :pipeline_id])
    |> validate_required([:title, :description])
    |> validate_inclusion(:status, ~w(open closed))
  end
end
