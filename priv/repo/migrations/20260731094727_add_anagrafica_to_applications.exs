defmodule Treby.Repo.Migrations.AddAnagraficaToApplications do
  use Ecto.Migration

  def change do
    alter table(:applications) do
      add :anagrafica, :map
    end

    execute("""
    UPDATE applications a
    SET anagrafica = jsonb_build_object(
      'name', c.name,
      'email', c.email,
      'phone', c.phone,
      'linkedin_url', c.linkedin_url
    )
    FROM candidates c
    WHERE a.candidate_id = c.id AND a.anagrafica IS NULL
    """)
  end
end
