defmodule Treby.Pipeline.Application do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "applications" do
    field :resume_url, :string
    field :applied_at, :utc_datetime
    field :custom_fields, :map, default: %{}
    field :reviewed, :boolean, default: false

    belongs_to :tenant, Treby.Tenants.Tenant
    belongs_to :job, Treby.Jobs.Job
    belongs_to :candidate, Treby.Candidates.Candidate
    belongs_to :pipeline_stage, Treby.Pipeline.PipelineStage

    has_many :notes, Treby.Notes.Note

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(application, attrs) do
    application
    |> cast(attrs, [
      :resume_url,
      :applied_at,
      :custom_fields,
      :tenant_id,
      :job_id,
      :candidate_id,
      :pipeline_stage_id,
      :reviewed
    ])
    |> validate_required([:job_id, :candidate_id, :pipeline_stage_id, :applied_at])
  end
end
