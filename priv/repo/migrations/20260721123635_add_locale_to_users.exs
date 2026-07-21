defmodule Treby.Repo.Migrations.AddLocaleToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :locale, :string, size: 5, default: "en", null: false
    end
  end
end
