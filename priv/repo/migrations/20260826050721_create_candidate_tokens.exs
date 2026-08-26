defmodule Treby.Repo.Migrations.CreateCandidateTokens do
  use Ecto.Migration

  def change do
    create table(:candidate_tokens, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :token, :string, null: false
      add :used_at, :utc_datetime
      add :expires_at, :utc_datetime, null: false

      add :candidate_id, references(:candidates, type: :binary_id, on_delete: :delete_all),
        null: false

      add :tenant_id, references(:tenants, type: :binary_id, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:candidate_tokens, [:token], unique: true)
    create index(:candidate_tokens, [:candidate_id])
    create index(:candidate_tokens, [:tenant_id])
  end
end
