defmodule Treby.Repo.Migrations.FixScheduledByColumn do
  use Ecto.Migration

  def change do
    rename table(:interview_events), :scheduled_by, to: :scheduled_by_id
  end
end
