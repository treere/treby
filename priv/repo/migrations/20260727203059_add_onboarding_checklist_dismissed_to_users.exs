defmodule Treby.Repo.Migrations.AddOnboardingChecklistDismissedToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :onboarding_checklist_dismissed, :boolean, default: false, null: false
    end
  end
end
