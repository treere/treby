defmodule Treby.Repo.Migrations.AddUsersTimezone do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :timezone, :string, null: false, default: "UTC"
    end
  end
end
