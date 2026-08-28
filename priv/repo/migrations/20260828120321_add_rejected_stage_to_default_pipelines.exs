defmodule Treby.Repo.Migrations.AddRejectedStageToDefaultPipelines do
  use Ecto.Migration

  import Ecto.Query
  alias Treby.Repo

  def up do
    default_pipeline_ids =
      from(p in "pipelines", where: p.is_default == true, select: p.id)
      |> Repo.all()

    for pipeline_id <- default_pipeline_ids do
      rejected_exists? =
        from(ps in "pipeline_stages",
          where: ps.pipeline_id == ^pipeline_id and ps.stage_type == "rejected",
          select: count(ps.id)
        )
        |> Repo.one() > 0

      unless rejected_exists? do
        max_position =
          from(ps in "pipeline_stages",
            where: ps.pipeline_id == ^pipeline_id,
            select: max(ps.position)
          )
          |> Repo.one() || -1

        now = NaiveDateTime.utc_now()

        Repo.insert_all("pipeline_stages", [
          %{
            id: Ecto.UUID.dump!(Ecto.UUID.generate()),
            pipeline_id: pipeline_id,
            name: "Rejected",
            position: max_position + 1,
            color: "#ef4444",
            stage_type: "rejected",
            inserted_at: now,
            updated_at: now
          }
        ])
      end
    end
  end

  def down do
    from(ps in "pipeline_stages",
      where: ps.stage_type == "rejected" and ps.name == "Rejected"
    )
    |> Repo.delete_all()
  end
end
