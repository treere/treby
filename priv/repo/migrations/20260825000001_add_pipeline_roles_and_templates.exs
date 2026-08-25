defmodule Treby.Repo.Migrations.AddPipelineRolesAndTemplates do
  use Ecto.Migration

  def change do
    # --- pipelines: add is_template ---
    alter table(:pipelines) do
      add :is_template, :boolean, null: false, default: false
    end

    create index(:pipelines, [:tenant_id, :is_template])

    # --- pipeline_stages: add min_examiners, scorecard_template_id ---
    alter table(:pipeline_stages) do
      add :min_examiners, :integer, null: false, default: 1

      add :scorecard_template_id,
          references(:scorecard_templates, type: :binary_id, on_delete: :nilify_all),
          null: true
    end

    create index(:pipeline_stages, [:scorecard_template_id])

    # --- pipeline_stage_examiners ---
    create table(:pipeline_stage_examiners, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :pipeline_stage_id,
          references(:pipeline_stages, type: :binary_id, on_delete: :delete_all),
          null: false

      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create unique_index(:pipeline_stage_examiners, [:pipeline_stage_id, :user_id])

    # --- pipeline_stage_reviewers ---
    create table(:pipeline_stage_reviewers, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :pipeline_stage_id,
          references(:pipeline_stages, type: :binary_id, on_delete: :delete_all),
          null: false

      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create unique_index(:pipeline_stage_reviewers, [:pipeline_stage_id, :user_id])

    # --- pipeline_stage_advancers ---
    create table(:pipeline_stage_advancers, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :pipeline_stage_id,
          references(:pipeline_stages, type: :binary_id, on_delete: :delete_all),
          null: false

      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create unique_index(:pipeline_stage_advancers, [:pipeline_stage_id, :user_id])

    # --- interview_event_examiners ---
    create table(:interview_event_examiners, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :interview_event_id,
          references(:interview_events, type: :binary_id, on_delete: :delete_all),
          null: false

      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false

      add :status, :string, null: false, default: "scheduled"

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create unique_index(:interview_event_examiners, [:interview_event_id, :user_id])
    create index(:interview_event_examiners, [:user_id])

    # --- booking_tokens: add pipeline_stage_id ---
    alter table(:booking_tokens) do
      add :pipeline_stage_id,
          references(:pipeline_stages, type: :binary_id, on_delete: :nilify_all),
          null: true
    end

    create index(:booking_tokens, [:pipeline_stage_id])
  end
end
