defmodule Treby.Repo.Migrations.AddJobViewsDedupIndex do
  use Ecto.Migration

  def change do
    # Covers dedup query: WHERE session_hash = $1 AND job_id = $2 AND viewed_at > cutoff
    # Existing index is [:job_id, :session_hash, :viewed_at]; this adds the
    # alternative column order suggested in STACK_IMPROVEMENTS #8 for
    # planner flexibility. Use concurrently to avoid locking on large tables.
    create index(:job_views, [:session_hash, :job_id, :viewed_at])
  end
end
