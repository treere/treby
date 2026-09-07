defmodule Treby.Repo.Migrations.AddCandidatesTenantEmailUniqueActive do
  use Ecto.Migration

  def change do
    # The expression mirrors the app normalization (`lower(trim(email))`);
    # blank emails are excluded so candidates without an address
    # (always created, never deduped) can never collide.
    create unique_index(:candidates, ["tenant_id", "lower(trim(email))"],
             where: "merged_into_id IS NULL AND nullif(trim(email), '') IS NOT NULL",
             name: :candidates_tenant_email_unique_active
           )
  end
end
