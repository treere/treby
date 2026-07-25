defmodule Treby.Repo.Migrations.AddSourceToApplications do
  use Ecto.Migration

  def change do
    alter table(:applications) do
      add :source, :string
    end
  end
end
