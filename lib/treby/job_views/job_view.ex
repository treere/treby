defmodule Treby.JobViews.JobView do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "job_views" do
    field :viewed_at, :utc_datetime
    field :session_hash, :string
    field :referer, :string
    field :utm_source, :string
    field :user_agent, :string

    belongs_to :job, Treby.Jobs.Job
    belongs_to :tenant, Treby.Tenants.Tenant

    field :inserted_at, :utc_datetime
  end

  @doc false
  def changeset(job_view, attrs) do
    job_view
    |> cast(attrs, [
      :job_id,
      :tenant_id,
      :viewed_at,
      :session_hash,
      :referer,
      :utm_source,
      :user_agent
    ])
    |> validate_required([:job_id, :tenant_id, :viewed_at, :session_hash])
    |> foreign_key_constraint(:job_id)
    |> foreign_key_constraint(:tenant_id)
  end
end
