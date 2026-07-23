defmodule Treby.Repo.Migrations.AddReviewedToApplications do
  use Ecto.Migration

  def change do
    alter table(:applications) do
      add :reviewed, :boolean, default: false, null: false
    end
  end
end
