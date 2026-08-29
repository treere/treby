defmodule Treby.Repo.Migrations.CreateRegistrationOtps do
  use Ecto.Migration

  def change do
    create table(:registration_otps, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :email, :string, null: false
      add :code, :string, null: false
      add :expires_at, :utc_datetime, null: false
      add :attempts, :integer, null: false, default: 0
      add :used_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create index(:registration_otps, [:code])
    create unique_index(:registration_otps, [:email], where: "used_at IS NULL")
  end
end
