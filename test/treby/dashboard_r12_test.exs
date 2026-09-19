defmodule Treby.DashboardR12Test do
  use Treby.DataCase, async: true

  alias Treby.{Tenants, Repo, Dashboard, Pipeline, Jobs}
  alias Treby.Accounts.User

  defp setup_tenant do
    suffix = System.unique_integer([:positive])
    {:ok, tenant} = Tenants.create_tenant(%{name: "R12 #{suffix}", slug: "r12-#{suffix}"})

    {:ok, user} =
      tenant
      |> Ecto.build_assoc(:users)
      |> User.changeset(%{
        email: "r12-#{suffix}@test.com",
        password: "password123",
        name: "R12",
        role: "admin"
      })
      |> Repo.insert()

    {:ok, _} =
      Treby.Memberships.create_membership(%{
        user_id: user.id,
        tenant_id: tenant.id,
        role: "admin"
      })

    {tenant, user}
  end

  defp create_candidate(tenant, name, email) do
    tenant
    |> Ecto.build_assoc(:candidates)
    |> Treby.Candidates.Candidate.changeset(%{name: name, email: email})
    |> Repo.insert!()
  end

  defp create_job(tenant) do
    pipeline_id = Pipeline.default_pipeline_id(tenant.id)

    tenant
    |> Ecto.build_assoc(:jobs)
    |> Treby.Jobs.Job.changeset(%{
      title: "Test Job #{System.unique_integer([:positive])}",
      description: "desc",
      pipeline_id: pipeline_id
    })
    |> Repo.insert!()
  end

  test "newly created candidate is not stale" do
    {tenant, _user} = setup_tenant()

    candidate =
      create_candidate(tenant, "Fresh", "fresh-#{System.unique_integer([:positive])}@test.com")

    job = create_job(tenant)
    stage = Pipeline.list_pipeline_stages_for_job(job.id) |> List.first()

    {:ok, app} =
      Pipeline.create_application(%{
        tenant_id: tenant.id,
        job_id: job.id,
        candidate_id: candidate.id,
        pipeline_stage_id: stage.id,
        applied_at: DateTime.utc_now()
      })

    # Fresh application with no activity log should NOT be stale (updated_at is now)
    stale = Dashboard.stale_candidates(tenant.id)

    refute Enum.any?(stale, &(&1.id == app.id)),
           "fresh app with recent updated_at should not be stale, got stale_ids: #{inspect(Enum.map(stale, & &1.id))}"
  end

  test "old candidate with no activity is stale after 7 days" do
    {tenant, _user} = setup_tenant()

    candidate =
      create_candidate(tenant, "Old", "old-#{System.unique_integer([:positive])}@test.com")

    job = create_job(tenant)
    stage = Pipeline.list_pipeline_stages_for_job(job.id) |> List.first()

    {:ok, app} =
      Pipeline.create_application(%{
        tenant_id: tenant.id,
        job_id: job.id,
        candidate_id: candidate.id,
        pipeline_stage_id: stage.id,
        applied_at: DateTime.utc_now()
      })

    # Backdate updated_at to 8 days ago
    old_date = DateTime.add(DateTime.utc_now(), -8, :day)
    Repo.update!(Ecto.Changeset.change(app, updated_at: old_date))

    stale = Dashboard.stale_candidates(tenant.id)
    assert Enum.any?(stale, &(&1.id == app.id)), "old app should be stale"
  end

  test "threshold is 7 days as per UI" do
    {tenant, _user} = setup_tenant()

    candidate =
      create_candidate(tenant, "Mid", "mid-#{System.unique_integer([:positive])}@test.com")

    job = create_job(tenant)
    stage = Pipeline.list_pipeline_stages_for_job(job.id) |> List.first()

    {:ok, app} =
      Pipeline.create_application(%{
        tenant_id: tenant.id,
        job_id: job.id,
        candidate_id: candidate.id,
        pipeline_stage_id: stage.id,
        applied_at: DateTime.utc_now()
      })

    # 6 days ago -> not stale (since threshold 7)
    six_days = DateTime.add(DateTime.utc_now(), -6, :day)
    Repo.update!(Ecto.Changeset.change(app, updated_at: six_days))
    stale = Dashboard.stale_candidates(tenant.id)
    refute Enum.any?(stale, &(&1.id == app.id)), "6 days should not be stale with 7-day threshold"

    # 8 days ago -> stale
    eight_days = DateTime.add(DateTime.utc_now(), -8, :day)
    Repo.update!(Ecto.Changeset.change(app, updated_at: eight_days))
    stale2 = Dashboard.stale_candidates(tenant.id)
    assert Enum.any?(stale2, &(&1.id == app.id)), "8 days should be stale"
  end
end
