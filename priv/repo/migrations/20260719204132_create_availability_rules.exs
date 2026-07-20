defmodule Treby.Repo.Migrations.CreateAvailabilityRules do
  use Ecto.Migration

  def change do
    create table(:availability_rules, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :day_of_week, :integer, null: false
      add :start_time, :time, null: false
      add :end_time, :time, null: false
      add :timezone, :string, null: false, default: "UTC"
      add :buffer_before, :integer, null: false, default: 15
      add :buffer_after, :integer, null: false, default: 15
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :tenant_id, references(:tenants, type: :binary_id, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:availability_rules, [:tenant_id, :user_id, :day_of_week])
    create index(:availability_rules, [:user_id])
    create index(:availability_rules, [:tenant_id])
  end
end
