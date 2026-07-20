defmodule Treby.Repo.Migrations.AddUniqueInterviewConstraint do
  use Ecto.Migration

  def change do
    create unique_index(:interview_events, [:interviewer_id, :start_at_utc],
             where: "status = 'scheduled'",
             name: "unique_scheduled_interview_per_interviewer_slot"
           )
  end
end
