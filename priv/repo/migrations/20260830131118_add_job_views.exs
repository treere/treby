defmodule Treby.Repo.Migrations.AddJobViews do
  use Ecto.Migration

  def change do
    create table(:job_views, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :job_id, references(:jobs, type: :binary_id, on_delete: :delete_all), null: false
      add :tenant_id, references(:tenants, type: :binary_id, on_delete: :delete_all), null: false
      add :viewed_at, :utc_datetime, null: false
      add :session_hash, :string, null: false
      add :referer, :string
      add :utm_source, :string
      add :user_agent, :string

      add :inserted_at, :utc_datetime, null: false, default: fragment("now()")
    end

    create index(:job_views, [:job_id, :viewed_at])
    create index(:job_views, [:tenant_id, :viewed_at])
    create index(:job_views, [:job_id, :session_hash, :viewed_at])
  end
end
