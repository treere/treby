defmodule Treby.Repo.Migrations.CreateCandidateMerges do
  use Ecto.Migration

  def change do
    create table(:candidate_merges, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :primary_candidate_id,
          references(:candidates, type: :binary_id, on_delete: :delete_all),
          null: false

      add :absorbed_candidate_id,
          references(:candidates, type: :binary_id, on_delete: :delete_all),
          null: false

      add :tenant_id, references(:tenants, type: :binary_id, on_delete: :delete_all), null: false
      add :actor_id, references(:users, type: :binary_id, on_delete: :nilify_all)

      add :merged_at, :utc_datetime, null: false
      add :application_mapping, :map, null: false, default: %{}
      add :thread_mapping, :map, null: false, default: %{}
      add :activity_mapping, :map, null: false, default: %{}

      timestamps(type: :utc_datetime)
    end

    create index(:candidate_merges, [:primary_candidate_id])
    create index(:candidate_merges, [:absorbed_candidate_id])
    create index(:candidate_merges, [:tenant_id])
  end
end
