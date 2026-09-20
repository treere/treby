defmodule Treby.Repo.Migrations.RemovePrimaryColorFromCareerPages do
  use Ecto.Migration

  def change do
    alter table(:career_pages) do
      remove :primary_color
    end
  end
end
