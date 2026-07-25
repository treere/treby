defmodule Treby.Repo.Migrations.SeedDefaultSources do
  use Ecto.Migration

  def up do
    execute """
    INSERT INTO sources (id, name, is_default, position, tenant_id, inserted_at, updated_at)
    SELECT
      gen_random_uuid(),
      ds.source_name,
      true,
      ROW_NUMBER() OVER (PARTITION BY ds.tenant_id ORDER BY ds.source_name),
      ds.tenant_id,
      NOW(),
      NOW()
    FROM (
      SELECT DISTINCT t.id AS tenant_id, unnest(ARRAY['LinkedIn', 'Indeed', 'Referral', 'Website', 'Other']) AS source_name
      FROM tenants t
    ) ds
    WHERE NOT EXISTS (
      SELECT 1 FROM sources s
      WHERE s.tenant_id = ds.tenant_id AND s.name = ds.source_name
    )
    """
  end

  def down do
    execute """
    DELETE FROM sources
    WHERE is_default = true
    AND name IN ('LinkedIn', 'Indeed', 'Referral', 'Website', 'Other')
    """
  end
end
