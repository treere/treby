defmodule Treby.Repo.Migrations.CreateDismissedMergeGroups do
  use Ecto.Migration

  def change do
    create table(:dismissed_merge_groups, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :tenant_id, references(:tenants, type: :binary_id, on_delete: :delete_all), null: false
      add :group_key, :string, null: false
      add :dismissed_by, references(:users, type: :binary_id, on_delete: :nilify_all)

      add :dismissed_at, :utc_datetime, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:dismissed_merge_groups, [:tenant_id, :group_key])
    create index(:dismissed_merge_groups, [:tenant_id])
  end
end
