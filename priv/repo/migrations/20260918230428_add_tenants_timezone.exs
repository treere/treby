defmodule Treby.Repo.Migrations.AddTenantsTimezone do
  use Ecto.Migration

  def change do
    alter table(:tenants) do
      add :timezone, :string, null: false, default: "UTC"
    end
  end
end
