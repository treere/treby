defmodule Treby.Repo.Migrations.CreateEmailTemplates do
  use Ecto.Migration

  def change do
    create table(:email_templates, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :stage_type, :string, null: false
      add :subject, :string, null: false
      add :body, :text, null: false
      add :tenant_id, references(:tenants, type: :binary_id, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:email_templates, [:tenant_id])
    create unique_index(:email_templates, [:stage_type, :tenant_id])
  end
end
