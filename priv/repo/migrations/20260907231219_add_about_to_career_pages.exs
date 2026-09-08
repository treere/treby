defmodule Treby.Repo.Migrations.AddAboutToCareerPages do
  use Ecto.Migration

  def change do
    alter table(:career_pages) do
      add :about, :string
    end
  end
end
