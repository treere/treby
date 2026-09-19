defmodule Treby.Repo.Migrations.AlterAvailabilityRulesMultiwindow do
  use Ecto.Migration

  def change do
    drop_if_exists(index(:availability_rules, [:tenant_id, :user_id, :day_of_week]))

    alter table(:availability_rules) do
      add :scope, :string, null: false, default: "user"
      modify(:user_id, :binary_id, null: true)
      remove :timezone
      remove :buffer_before
      remove :buffer_after
    end
  end
end
