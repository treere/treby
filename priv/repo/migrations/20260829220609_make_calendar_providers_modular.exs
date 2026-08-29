defmodule Treby.Repo.Migrations.MakeCalendarProvidersModular do
  use Ecto.Migration

  def up do
    # calendar_connections: provider_email, multiple connections per user per provider
    rename table(:calendar_connections), :google_email, to: :provider_email
    drop unique_index(:calendar_connections, [:tenant_id, :user_id])
    create unique_index(:calendar_connections, [:tenant_id, :user_id, :provider])

    # interview_events: provider-agnostic event reference + owner
    rename table(:interview_events), :google_event_id, to: :provider_event_id

    alter table(:interview_events) do
      add :calendar_provider, :string
      add :calendar_owner_id, references(:users, type: :binary_id, on_delete: :nilify_all)
    end

    execute("""
    UPDATE interview_events
    SET calendar_provider = 'google'
    WHERE provider_event_id IS NOT NULL
    """)

    execute("""
    UPDATE interview_events e
    SET calendar_owner_id = (
      SELECT ee.user_id
      FROM interview_event_examiners ee
      WHERE ee.interview_event_id = e.id
      ORDER BY ee.inserted_at, ee.id
      LIMIT 1
    )
    WHERE e.calendar_owner_id IS NULL AND e.provider_event_id IS NOT NULL
    """)

    create index(:interview_events, [:calendar_owner_id])
  end

  def down do
    drop index(:interview_events, [:calendar_owner_id])

    execute("""
    UPDATE interview_events
    SET calendar_owner_id = NULL,
        calendar_provider = NULL
    """)

    alter table(:interview_events) do
      remove :calendar_owner_id
      remove :calendar_provider
    end

    rename table(:interview_events), :provider_event_id, to: :google_event_id

    drop unique_index(:calendar_connections, [:tenant_id, :user_id, :provider])
    create unique_index(:calendar_connections, [:tenant_id, :user_id])
    rename table(:calendar_connections), :provider_email, to: :google_email
  end
end
