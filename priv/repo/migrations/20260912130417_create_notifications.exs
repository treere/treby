defmodule Treby.Repo.Migrations.CreateNotifications do
  use Ecto.Migration

  def change do
    create table(:notifications, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :tenant_id, references(:tenants, type: :binary_id, on_delete: :delete_all), null: false
      add :recipient_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :actor_id, references(:users, type: :binary_id, on_delete: :nilify_all)
      add :type, :string, null: false
      add :title, :text, null: false
      add :body, :text
      add :link, :string

      add :read_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create index(:notifications, [:recipient_id, :read_at])
    create index(:notifications, [:tenant_id])
    create index(:notifications, [:recipient_id, :inserted_at])
  end
end
