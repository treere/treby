defmodule Treby.Repo.Migrations.CreateNotes do
  use Ecto.Migration

  def change do
    create table(:notes, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :content, :text, null: false
      add :type, :string, null: false, default: "note"
      add :rating, :integer
      add :tenant_id, references(:tenants, type: :binary_id, on_delete: :delete_all), null: false

      add :application_id, references(:applications, type: :binary_id, on_delete: :delete_all),
        null: false

      add :author_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:notes, [:tenant_id])
    create index(:notes, [:application_id])
    create index(:notes, [:author_id])
  end
end
