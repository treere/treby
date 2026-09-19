defmodule Treby.Repo.Migrations.RenameGdprToDataPrivacy do
  use Ecto.Migration

  def up do
    execute "ALTER TABLE gdpr_requests RENAME TO data_privacy_requests"

    execute "ALTER INDEX gdpr_requests_tenant_id_status_index RENAME TO data_privacy_requests_tenant_id_status_index"

    execute "ALTER INDEX gdpr_requests_expires_at_index RENAME TO data_privacy_requests_expires_at_index"

    execute "ALTER INDEX gdpr_requests_tenant_id_type_index RENAME TO data_privacy_requests_tenant_id_type_index"

    execute "ALTER INDEX gdpr_requests_pending_unique RENAME TO data_privacy_requests_pending_unique"

    execute """
    UPDATE audit_events
    SET action = regexp_replace(action, '^gdpr\\.', 'data_privacy.')
    WHERE action LIKE 'gdpr.%'
    """

    execute """
    UPDATE audit_events
    SET entity_type = 'data_privacy_request'
    WHERE entity_type = 'gdpr_request'
    """

    execute """
    UPDATE tenants
    SET settings = settings - 'gdpr_pending_erasure' || jsonb_build_object('data_privacy_pending_erasure', settings->'gdpr_pending_erasure')
    WHERE settings ? 'gdpr_pending_erasure'
    """

    execute """
    UPDATE tenants
    SET settings = settings - 'gdpr_erased_at' || jsonb_build_object('data_privacy_erased_at', settings->'gdpr_erased_at')
    WHERE settings ? 'gdpr_erased_at'
    """

    execute """
    UPDATE data_privacy_requests
    SET metadata = metadata - 'gdpr_pending_erasure' || jsonb_build_object('data_privacy_pending_erasure', metadata->'gdpr_pending_erasure')
    WHERE metadata ? 'gdpr_pending_erasure'
    """
  end

  def down do
    execute """
    UPDATE data_privacy_requests
    SET metadata = metadata - 'data_privacy_pending_erasure' || jsonb_build_object('gdpr_pending_erasure', metadata->'data_privacy_pending_erasure')
    WHERE metadata ? 'data_privacy_pending_erasure'
    """

    execute """
    UPDATE tenants
    SET settings = settings - 'data_privacy_erased_at' || jsonb_build_object('gdpr_erased_at', settings->'data_privacy_erased_at')
    WHERE settings ? 'data_privacy_erased_at'
    """

    execute """
    UPDATE tenants
    SET settings = settings - 'data_privacy_pending_erasure' || jsonb_build_object('gdpr_pending_erasure', settings->'data_privacy_pending_erasure')
    WHERE settings ? 'data_privacy_pending_erasure'
    """

    execute """
    UPDATE audit_events
    SET entity_type = 'gdpr_request'
    WHERE entity_type = 'data_privacy_request'
    """

    execute """
    UPDATE audit_events
    SET action = regexp_replace(action, '^data_privacy\\.', 'gdpr.')
    WHERE action LIKE 'data_privacy.%'
    """

    execute "ALTER INDEX data_privacy_requests_pending_unique RENAME TO gdpr_requests_pending_unique"

    execute "ALTER INDEX data_privacy_requests_tenant_id_type_index RENAME TO gdpr_requests_tenant_id_type_index"

    execute "ALTER INDEX data_privacy_requests_expires_at_index RENAME TO gdpr_requests_expires_at_index"

    execute "ALTER INDEX data_privacy_requests_tenant_id_status_index RENAME TO gdpr_requests_tenant_id_status_index"

    execute "ALTER TABLE data_privacy_requests RENAME TO gdpr_requests"
  end
end
