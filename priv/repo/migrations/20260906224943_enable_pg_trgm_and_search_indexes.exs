defmodule Treby.Repo.Migrations.EnablePgTrgmAndSearchIndexes do
  use Ecto.Migration

  # NOTE: self-hosted Postgres runs as superuser by default, so
  # CREATE EXTENSION works. If your DBA manages extensions, ask them to run
  # `CREATE EXTENSION IF NOT EXISTS pg_trgm` beforehand and skip that line.
  @disable_ddl_transaction true

  def change do
    execute "CREATE EXTENSION IF NOT EXISTS pg_trgm", ""

    execute(
      "CREATE INDEX CONCURRENTLY IF NOT EXISTS candidates_name_trgm_idx ON candidates USING gin (name gin_trgm_ops)",
      "DROP INDEX CONCURRENTLY IF EXISTS candidates_name_trgm_idx"
    )

    execute(
      "CREATE INDEX CONCURRENTLY IF NOT EXISTS candidates_email_trgm_idx ON candidates USING gin (email gin_trgm_ops)",
      "DROP INDEX CONCURRENTLY IF EXISTS candidates_email_trgm_idx"
    )

    execute(
      "CREATE INDEX CONCURRENTLY IF NOT EXISTS jobs_title_trgm_idx ON jobs USING gin (title gin_trgm_ops)",
      "DROP INDEX CONCURRENTLY IF EXISTS jobs_title_trgm_idx"
    )
  end
end
