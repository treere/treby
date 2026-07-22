defmodule Treby.Repo.Migrations.BackfillPipelinesAndStageTypes do
  use Ecto.Migration

  def up do
    # 1. For each tenant, create a "Default" pipeline
    execute """
    INSERT INTO pipelines (id, name, is_default, tenant_id, inserted_at, updated_at)
    SELECT gen_random_uuid(), 'Default', true, t.id, NOW(), NOW()
    FROM tenants t
    """

    # 2. Update pipeline_stages to point to the tenant's default pipeline
    execute """
    UPDATE pipeline_stages ps
    SET pipeline_id = (
      SELECT p.id FROM pipelines p
      WHERE p.tenant_id = ps.tenant_id AND p.is_default = true
      LIMIT 1
    )
    WHERE ps.pipeline_id IS NULL
    """

    # 3. Backfill stage_type based on stage name
    execute "UPDATE pipeline_stages SET stage_type = 'new' WHERE name = 'New' AND stage_type IS NULL"

    execute "UPDATE pipeline_stages SET stage_type = 'interview' WHERE name = 'Interview' AND stage_type IS NULL"

    execute "UPDATE pipeline_stages SET stage_type = 'offer' WHERE name = 'Offer' AND stage_type IS NULL"

    execute "UPDATE pipeline_stages SET stage_type = 'hired' WHERE name = 'Hired' AND stage_type IS NULL"

    # 4. Make pipeline_id NOT NULL on pipeline_stages and drop tenant_id
    execute "ALTER TABLE pipeline_stages ALTER COLUMN pipeline_id SET NOT NULL"
    execute "ALTER TABLE pipeline_stages DROP COLUMN tenant_id"
  end

  def down do
    execute "ALTER TABLE pipeline_stages ADD COLUMN tenant_id UUID REFERENCES tenants(id) ON DELETE CASCADE"

    execute "UPDATE pipeline_stages SET tenant_id = (SELECT p.tenant_id FROM pipelines p WHERE p.id = pipeline_stages.pipeline_id)"

    execute "ALTER TABLE pipeline_stages ALTER COLUMN tenant_id SET NOT NULL"
    execute "ALTER TABLE pipeline_stages ALTER COLUMN pipeline_id DROP NOT NULL"
    execute "UPDATE pipeline_stages SET pipeline_id = NULL, stage_type = NULL"
    execute "DELETE FROM pipelines WHERE name = 'Default' AND is_default = true"
  end
end
