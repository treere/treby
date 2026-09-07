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

  describe "search with LIKE wildcards" do
    test "% matches literally, not as a wildcard" do
      {tenant, _user} = setup_tenant()

      {:ok, _job} =
        tenant
        |> Ecto.build_assoc(:jobs)
        |> Job.changeset(%{title: "Backend Engineer", description: "Elixir work"})
        |> Repo.insert()

      assert Jobs.search_visible_jobs(tenant.id, "%") == []
      assert Jobs.search_all_visible_jobs("%") == []
    end
  end

  describe "visible requires open status" do
    test "closed job cannot be made visible" do
      {tenant, _user} = setup_tenant()

      {:ok, job} =
        tenant
        |> Ecto.build_assoc(:jobs)
        |> Job.changeset(%{title: "Backend Engineer", description: "Elixir work", visible: false})
        |> Repo.insert()

      {:ok, closed} = job |> Job.changeset(%{status: "closed"}) |> Repo.update()

      assert {:error, changeset} =
               closed |> Job.changeset(%{visible: true}) |> Repo.update()

      assert {"cannot be visible when the job is closed", []} = changeset.errors[:visible]
    end

    test "closing an open visible job keeps working" do
      {tenant, _user} = setup_tenant()

      {:ok, job} =
        tenant
        |> Ecto.build_assoc(:jobs)
        |> Job.changeset(%{title: "Backend Engineer", description: "Elixir work"})
        |> Repo.insert()

      assert {:ok, closed} = job |> Job.changeset(%{status: "closed"}) |> Repo.update()
      assert closed.status == "closed"
    end

    test "open job stays publishable" do
      {tenant, _user} = setup_tenant()

      assert {:ok, job} =
               tenant
               |> Ecto.build_assoc(:jobs)
               |> Job.changeset(%{
                 title: "Backend Engineer",
                 description: "Elixir work",
                 status: "closed",
                 visible: false
               })
               |> Repo.insert()

      assert {:ok, opened} =
               job |> Job.changeset(%{status: "open", visible: true}) |> Repo.update()

      assert opened.visible == true
    end
  end

  describe "uuid v7 ordering" do
    test "same-timestamp jobs order by descending id" do
      import Ecto.Query

      {tenant, _user} = setup_tenant()

      {:ok, _first} =
        tenant
        |> Ecto.build_assoc(:jobs)
        |> Job.changeset(%{title: "Backend Engineer", description: "Elixir work"})
        |> Repo.insert()

      {:ok, second} =
        tenant
        |> Ecto.build_assoc(:jobs)
        |> Job.changeset(%{title: "Frontend Engineer", description: "Phoenix work"})
        |> Repo.insert()

      now = DateTime.utc_now() |> DateTime.truncate(:second)

      Job
      |> where([j], j.tenant_id == ^tenant.id)
      |> Repo.update_all(set: [inserted_at: now])

      assert [%{id: newest_id} | _] = Jobs.list_jobs(tenant.id)
      assert newest_id == second.id
    end
  end
end
