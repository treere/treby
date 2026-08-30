defmodule Treby.JobsTest do
  use Treby.DataCase, async: true

  alias Treby.{Tenants, Jobs, Repo}
  alias Treby.Accounts.User
  alias Treby.Jobs.Job

  defp setup_tenant do
    {:ok, tenant} =
      Tenants.create_tenant(%{
        name: "Test Corp",
        slug: "test-#{System.unique_integer([:positive])}"
      })

    {:ok, user} =
      tenant
      |> Ecto.build_assoc(:users)
      |> User.changeset(%{
        email: "test-#{System.unique_integer([:positive])}@test.com",
        password: "password123",
        name: "Test User",
        role: "admin"
      })
      |> Repo.insert()

    {:ok, _} =
      Treby.Memberships.create_membership(%{
        user_id: user.id,
        tenant_id: tenant.id,
        role: user.role
      })

    {tenant, user}
  end

  describe "tenant_has_jobs?/1" do
    test "returns false when tenant has no jobs" do
      {tenant, _user} = setup_tenant()
      refute Jobs.tenant_has_jobs?(tenant.id)
    end

    test "returns true when tenant has jobs" do
      {tenant, _user} = setup_tenant()

      {:ok, pipeline} =
        Treby.Pipeline.create_pipeline(%{
          name: "Default",
          tenant_id: tenant.id,
          is_default: true
        })

      {:ok, _job} =
        tenant
        |> Ecto.build_assoc(:jobs)
        |> Job.changeset(%{
          title: "Software Engineer",
          description: "Build things",
          pipeline_id: pipeline.id
        })
        |> Repo.insert()

      assert Jobs.tenant_has_jobs?(tenant.id)
    end
  end
end
