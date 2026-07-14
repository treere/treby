defmodule Treby.Repo.Migrations.CreateCareerPages do
  use Ecto.Migration

  def change do
    create table(:career_pages, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :title, :string, null: false
      add :description, :text
      add :logo_url, :string
      add :primary_color, :string, default: "#3b82f6"
      add :published, :boolean, default: false
      add :tenant_id, references(:tenants, type: :binary_id, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:career_pages, [:tenant_id], unique: true)
  end
end
