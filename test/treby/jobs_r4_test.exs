defmodule Treby.JobsR4Test do
  use Treby.DataCase, async: false

  alias Treby.{Tenants, Repo, Jobs}
  alias Treby.Accounts.User
  alias Treby.Jobs.Job

  defp setup_tenant do
    suffix = System.unique_integer([:positive])

    {:ok, tenant} =
      Tenants.create_tenant(%{name: "R4 #{suffix}", slug: "r4-#{suffix}"})

    {:ok, user} =
      tenant
      |> Ecto.build_assoc(:users)
      |> User.changeset(%{
        email: "r4-#{suffix}@test.com",
        password: "password123",
        name: "R4 User",
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

  test "closing visible job without touching visible coerces to private" do
    {tenant, _user} = setup_tenant()

    {:ok, job} =
      Jobs.create_job(%{
        title: "Visible Open",
        description: "desc",
        tenant_id: tenant.id,
        pipeline_id: Treby.Pipeline.default_pipeline_id(tenant.id),
        status: "open",
        visible: true
      })

    assert job.visible == true
    assert job.status == "open"

    # update only status to closed, without visible param - bug: remains visible=true
    {:ok, closed} = Jobs.update_job(job, %{"status" => "closed"})

    # expected: closed jobs are private
    assert closed.status == "closed"

    assert closed.visible == false,
           "expected closing to coerce visible to false, got visible=#{closed.visible} status=#{closed.status} — R4 bug"
  end

  test "closed job cannot be made visible via changeset" do
    {tenant, _user} = setup_tenant()

    {:ok, job} =
      Jobs.create_job(%{
        title: "Closed Private",
        description: "desc",
        tenant_id: tenant.id,
        pipeline_id: Treby.Pipeline.default_pipeline_id(tenant.id),
        status: "closed",
        visible: false
      })

    changeset = Job.changeset(job, %{visible: true})
    assert {"cannot be visible when the job is closed", []} == changeset.errors[:visible]
  end

  test "creating closed+visible true coerces to private" do
    {tenant, _user} = setup_tenant()

    {:ok, job} =
      Jobs.create_job(%{
        title: "Bad",
        description: "desc",
        tenant_id: tenant.id,
        pipeline_id: Treby.Pipeline.default_pipeline_id(tenant.id),
        status: "closed",
        visible: true
      })

    assert job.status == "closed"
    assert job.visible == false
  end
end
