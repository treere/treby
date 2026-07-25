defmodule Treby.Repo.Migrations.CreateScorecards do
  use Ecto.Migration

  def change do
    create table(:scorecards, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :scores, :map, null: false, default: %{}
      add :recommendation, :string
      add :notes, :text

      add :interview_event_id,
          references(:interview_events, type: :binary_id, on_delete: :delete_all), null: false

      add :interviewer_id, references(:users, type: :binary_id, on_delete: :delete_all),
        null: false

      add :tenant_id, references(:tenants, type: :binary_id, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:scorecards, [:interview_event_id])
    create index(:scorecards, [:interviewer_id])
    create index(:scorecards, [:tenant_id])
    create unique_index(:scorecards, [:interview_event_id, :interviewer_id])
  end
end
