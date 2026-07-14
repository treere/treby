defmodule Treby.Repo.Migrations.CreateCandidates do
  use Ecto.Migration

  def change do
    create table(:candidates, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :email, :string, null: false
      add :phone, :string
      add :linkedin_url, :string
      add :custom_fields, :map, default: %{}
      add :tenant_id, references(:tenants, type: :binary_id, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:candidates, [:tenant_id])
    create index(:candidates, [:tenant_id, :email])
  end
end
