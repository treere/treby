defmodule Treby.Repo.Migrations.AddStructuredFieldsToJobs do
  use Ecto.Migration

  def change do
    alter table(:jobs) do
      add :location, :string
      add :employment_type, :string
      add :workplace_type, :string
    end
  end
end
