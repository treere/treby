defmodule Treby.Repo.Migrations.BackfillInterviewEventExaminers do
  use Ecto.Migration

  def up do
    # Backfill interview_event_examiners from existing interviewer_id on interview_events
    execute """
    INSERT INTO interview_event_examiners (id, interview_event_id, user_id, status, inserted_at)
    SELECT gen_random_uuid(), ie.id, ie.interviewer_id, 'scheduled', ie.inserted_at
    FROM interview_events ie
    WHERE ie.interviewer_id IS NOT NULL
    """

    # Backfill booking_tokens.pipeline_stage_id from the application's current stage
    execute """
    UPDATE booking_tokens bt
    SET pipeline_stage_id = a.pipeline_stage_id
    FROM applications a
    WHERE bt.application_id = a.id
      AND bt.pipeline_stage_id IS NULL
    """
  end

  def down do
    execute "DELETE FROM interview_event_examiners"
    execute "UPDATE booking_tokens SET pipeline_stage_id = NULL"
  end
end
