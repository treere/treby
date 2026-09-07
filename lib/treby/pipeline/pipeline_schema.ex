defmodule Treby.Pipeline.Pipeline do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, Ecto.UUID, autogenerate: [version: 7, precision: :monotonic]}
  @foreign_key_type :binary_id

  schema "pipelines" do
    field :name, :string
    field :is_default, :boolean, default: false

    belongs_to :tenant, Treby.Tenants.Tenant
    has_many :pipeline_stages, Treby.Pipeline.PipelineStage

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(pipeline, attrs) do
    pipeline
    |> cast(attrs, [:name, :is_default, :tenant_id])
    |> validate_required([:name])
    |> unique_constraint(:name, name: :pipelines_tenant_id_name_index)
  end
end
