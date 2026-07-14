defmodule Treby.Repo.Migrations.CreateInvites do
  use Ecto.Migration

  def change do
    create table(:invites, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :email, :string, null: false
      add :role, :string, null: false, default: "member"
      add :token, :string, null: false
      add :accepted_at, :utc_datetime
      add :expires_at, :utc_datetime, null: false
      add :tenant_id, references(:tenants, type: :binary_id, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:invites, [:tenant_id])
    create unique_index(:invites, [:tenant_id, :email])
    create unique_index(:invites, [:token])
  end
end
