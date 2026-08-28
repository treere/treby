defmodule Treby.Repo.Migrations.CreateCandidateOtps do
  use Ecto.Migration

  def change do
    create table(:candidate_otps, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :code, :string, null: false
      add :expires_at, :utc_datetime, null: false
      add :attempts, :integer, null: false, default: 0
      add :used_at, :utc_datetime

      add :candidate_id, references(:candidates, type: :binary_id, on_delete: :delete_all),
        null: false

      add :tenant_id, references(:tenants, type: :binary_id, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:candidate_otps, [:candidate_id])
    create index(:candidate_otps, [:tenant_id])
    create index(:candidate_otps, [:code])
  end
end
