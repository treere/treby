defmodule Treby.Repo.Migrations.AddRejectionReasonToApplications do
  use Ecto.Migration

  def change do
    alter table(:applications, primary_key: false) do
      add :rejection_reason, :text
    end
  end
end
