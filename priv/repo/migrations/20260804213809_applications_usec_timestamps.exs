defmodule Treby.Repo.Migrations.ApplicationsUsecTimestamps do
  use Ecto.Migration

  def change do
    alter table(:applications) do
      modify :inserted_at, :utc_datetime_usec
      modify :updated_at, :utc_datetime_usec
    end
  end
end
