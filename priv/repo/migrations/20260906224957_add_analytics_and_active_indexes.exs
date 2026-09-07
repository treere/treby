defmodule Treby.Repo.Migrations.AddAnalyticsAndActiveIndexes do
  use Ecto.Migration

  def change do
    create index(:activity_log, [:entity_type, :entity_id, :inserted_at],
             name: :activity_log_entity_time_idx
           )

    create index(:candidates, [:tenant_id],
             where: "merged_into_id IS NULL",
             name: :candidates_active_tenant_idx
           )
  end
end
