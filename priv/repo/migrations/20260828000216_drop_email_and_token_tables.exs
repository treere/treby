defmodule Treby.Repo.Migrations.DropEmailAndTokenTables do
  use Ecto.Migration

  def up do
    execute("DROP TABLE IF EXISTS scheduled_emails CASCADE")
    execute("DROP TABLE IF EXISTS email_messages CASCADE")
    execute("DROP TABLE IF EXISTS email_threads CASCADE")
    execute("DROP TABLE IF EXISTS candidate_tokens CASCADE")
    execute("DROP TABLE IF EXISTS booking_tokens CASCADE")
  end

  def down do
    raise "irreversible"
  end
end
