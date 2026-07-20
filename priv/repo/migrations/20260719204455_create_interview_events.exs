defmodule Treby.Repo.Migrations.CreateInterviewEvents do
  use Ecto.Migration

  def change do
    create table(:interview_events, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :start_at_utc, :utc_datetime, null: false
      add :end_at_utc, :utc_datetime, null: false
      add :duration_minutes, :integer, null: false
      add :video_conf_url, :string
      add :google_event_id, :string
      add :status, :string, null: false, default: "scheduled"
      add :notes, :string
      add :scheduled_by, references(:users, type: :binary_id, on_delete: :nilify_all)

      add :interviewer_id, references(:users, type: :binary_id, on_delete: :nilify_all),
        null: false

      add :application_id, references(:applications, type: :binary_id, on_delete: :delete_all),
        null: false

      add :tenant_id, references(:tenants, type: :binary_id, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:interview_events, [:application_id])
    create index(:interview_events, [:interviewer_id])
    create index(:interview_events, [:tenant_id])
    create index(:interview_events, [:status])
    create index(:interview_events, [:start_at_utc])
  end
end
