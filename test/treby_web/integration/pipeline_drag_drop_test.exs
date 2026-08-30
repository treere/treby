defmodule TrebyWeb.PipelineDragDropTest do
  use TrebyWeb.ConnCase, async: false

  alias Treby.{Tenants, Candidates, Pipeline, Repo}
  alias Treby.Accounts.User
  alias Treby.Jobs.Job

  defp setup_pipeline do
    {:ok, tenant} =
      Tenants.create_tenant(%{
        name: "Pipeline Test Corp",
        slug: "pipeline-test-#{System.unique_integer([:positive])}"
      })

    pipeline_id = Pipeline.default_pipeline_id(tenant.id)
    stages = Pipeline.list_pipeline_stages(pipeline_id)

    {:ok, _user} =
      tenant
      |> Ecto.build_assoc(:users)
      |> User.changeset(%{
        email: "pipeline-#{System.unique_integer([:positive])}@test.com",
        password: "password123",
        name: "Pipeline User",
        role: "admin"
      })
      |> Repo.insert()

    {:ok, _} =
      Treby.Memberships.create_membership(%{
        user_id: _user.id,
        tenant_id: tenant.id,
        role: _user.role
      })

    {:ok, job} =
      tenant
      |> Ecto.build_assoc(:jobs)
      |> Job.changeset(%{
        title: "Pipeline Job",
        description: "Test job"
      })
      |> Repo.insert()

    {:ok, candidate} =
      tenant
      |> Ecto.build_assoc(:candidates)
      |> Candidates.Candidate.changeset(%{
        name: "Pipeline Candidate",
        email: "pipeline-candidate@test.com"
      })
      |> Repo.insert()

    {:ok, application} =
      tenant
      |> Ecto.build_assoc(:applications)
      |> Ecto.Changeset.change(%{
        job_id: job.id,
        candidate_id: candidate.id,
        pipeline_stage_id: Enum.at(stages, 0).id,
        applied_at: DateTime.utc_now() |> DateTime.truncate(:second)
      })
      |> Repo.insert()

    {tenant, job, application, stages}
  end

  describe "pipeline move" do
    test "application can be moved to a different stage" do
      {_tenant, _job, application, stages} = setup_pipeline()

      target_stage = Enum.at(stages, 2)
      assert {:ok, updated} = Pipeline.move_application(application, target_stage.id)
      assert updated.pipeline_stage_id == target_stage.id
    end

    test "pipeline counts update after move" do
      {_tenant, job, application, stages} = setup_pipeline()
      target_stage = Enum.at(stages, 2)

      Pipeline.move_application(application, target_stage.id)

      counts = Pipeline.pipeline_counts_per_stage_for_job(job.id)
      new_stage_count = Enum.find(counts, &(&1.stage.id == Enum.at(stages, 0).id))
      target_stage_count = Enum.find(counts, &(&1.stage.id == target_stage.id))

      assert new_stage_count.count == 0
      assert target_stage_count.count == 1
    end
  end
end
