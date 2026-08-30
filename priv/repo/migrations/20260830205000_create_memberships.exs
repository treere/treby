defmodule Treby.Repo.Migrations.CreateMemberships do
  use Ecto.Migration

  def up do
    create table(:memberships, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :tenant_id, references(:tenants, type: :binary_id, on_delete: :delete_all), null: false
      add :role, :string, null: false, default: "member"

      timestamps(type: :utc_datetime)
    end

    create unique_index(:memberships, [:user_id, :tenant_id])
    create index(:memberships, [:user_id])
    create index(:memberships, [:tenant_id])

    # Global case-insensitive unique email — enforces one identity per email.
    # The existing unique_index([:tenant_id, :email]) stays for one release.
    create unique_index(:users, ["lower(email)"], name: :users_email_unique_lower_index)

    # Backfill: one membership per existing user (idempotent).
    # If duplicate lower(email) rows exist, the unique index creation above
    # will have already failed, forcing manual merge review.
    execute """
    INSERT INTO memberships (id, user_id, tenant_id, role, inserted_at, updated_at)
    SELECT gen_random_uuid(), id, tenant_id, role, now(), now() FROM users
    ON CONFLICT (user_id, tenant_id) DO NOTHING
    """
  end

  def down do
    execute "DELETE FROM memberships"

    drop_if_exists unique_index(:users, ["lower(email)"], name: :users_email_unique_lower_index)
    drop_if_exists index(:memberships, [:tenant_id])
    drop_if_exists index(:memberships, [:user_id])
    drop_if_exists unique_index(:memberships, [:user_id, :tenant_id])
    drop table(:memberships)
  end
end
