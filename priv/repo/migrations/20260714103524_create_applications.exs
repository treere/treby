defmodule Treby.Repo.Migrations.CreateApplications do
  use Ecto.Migration

  def change do
    create table(:applications, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :resume_url, :string
      add :applied_at, :utc_datetime, null: false
      add :custom_fields, :map, default: %{}
      add :tenant_id, references(:tenants, type: :binary_id, on_delete: :delete_all), null: false
      add :job_id, references(:jobs, type: :binary_id, on_delete: :delete_all), null: false

      add :candidate_id, references(:candidates, type: :binary_id, on_delete: :delete_all),
        null: false

      add :pipeline_stage_id,
          references(:pipeline_stages, type: :binary_id, on_delete: :nilify_all), null: false

      timestamps(type: :utc_datetime_usec)
    end

    create index(:applications, [:tenant_id])
    create index(:applications, [:job_id])
    create index(:applications, [:candidate_id])
    create index(:applications, [:pipeline_stage_id])
    create index(:applications, [:tenant_id, :job_id])
  end
end
