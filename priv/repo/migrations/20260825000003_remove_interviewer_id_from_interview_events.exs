defmodule Treby.Repo.Migrations.RemoveInterviewerIdFromInterviewEvents do
  use Ecto.Migration

  def up do
    # Drop the partial unique index that depends on interviewer_id
    drop_if_exists index(:interview_events, [:interviewer_id, :start_at_utc],
                     name: "unique_scheduled_interview_per_interviewer_slot"
                   )

    # Drop the index on interviewer_id
    drop_if_exists index(:interview_events, [:interviewer_id])

    alter table(:interview_events) do
      remove :interviewer_id
    end
  end

  def down do
    alter table(:interview_events) do
      add :interviewer_id, references(:users, type: :binary_id, on_delete: :nilify_all),
        null: true
    end

    execute """
    UPDATE interview_events ie
    SET interviewer_id = (
      SELECT iee.user_id
      FROM interview_event_examiners iee
      WHERE iee.interview_event_id = ie.id
      ORDER BY iee.inserted_at
      LIMIT 1
    )
    """

    create index(:interview_events, [:interviewer_id])

    create unique_index(:interview_events, [:interviewer_id, :start_at_utc],
             where: "status = 'scheduled'",
             name: "unique_scheduled_interview_per_interviewer_slot"
           )
  end
end
