defmodule Treby.Repo.Migrations.AddRolePermissionsAndNewRoles do
  use Ecto.Migration

  def change do
    create table(:role_permissions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :tenant_id, references(:tenants, type: :binary_id, on_delete: :delete_all), null: false
      add :role, :string, null: false
      add :action, :string, null: false
      add :allowed, :boolean, null: false, default: true

      timestamps(type: :utc_datetime)
    end

    create unique_index(:role_permissions, [:tenant_id, :role, :action])
    create index(:role_permissions, [:tenant_id])

    execute(
      "UPDATE memberships SET role = 'recruiter' WHERE role = 'member'",
      "UPDATE memberships SET role = 'member' WHERE role = 'recruiter'"
    )

    execute(
      "UPDATE invites SET role = 'recruiter' WHERE role = 'member'",
      "UPDATE invites SET role = 'member' WHERE role = 'recruiter'"
    )
  end
end
