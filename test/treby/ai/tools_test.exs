defmodule Treby.AI.ToolsTest do
  use Treby.DataCase, async: false

  alias Treby.AI.Tools
  alias Treby.AI.Tools.{CreateJob, DeleteJob, ExplainPage, ListJobs, ProposeFormFill, UpdateJob}
  alias Treby.{Repo, Tenants}
  alias Treby.Accounts.User
  alias Treby.Jobs.Job

  defp tenant_with_user do
    {:ok, tenant} =
      Tenants.create_tenant(%{
        name: "AI Tools #{System.unique_integer([:positive])}",
        slug: "ai-tools-#{System.unique_integer([:positive])}"
      })

    {:ok, user} =
      tenant
      |> Ecto.build_assoc(:users)
      |> User.changeset(%{
        email: "ai-tools-#{System.unique_integer([:positive])}@test.com",
        password: "password123",
        name: "AI Tools User",
        role: "admin"
      })
      |> Repo.insert()

    {tenant, user}
  end

  defp create_job(tenant, attrs) do
    tenant
    |> Ecto.build_assoc(:jobs)
    |> Job.changeset(Map.merge(%{title: "Job", description: "desc"}, attrs))
    |> Repo.insert!()
  end

  test "all tools are registered with a schema" do
    assert length(Tools.all()) == 100

    for tool <- Tools.all() do
      assert is_binary(tool.name())
      assert is_binary(tool.description())
      assert is_map(tool.schema())
      assert tool.schema()["type"] == "object"
      assert is_boolean(tool.destructive?())
      assert Tools.required_role(tool) in [:any, :admin]
    end
  end

  test "tool names are unique" do
    names = Enum.map(Tools.all(), & &1.name())
    assert Enum.uniq(names) == names
  end

  test "required_role defaults to :any and flags admin tools" do
    assert Tools.required_role(Tools.ListJobs) == :any
    assert Tools.required_role(Tools.DeleteJob) == :admin
    assert Tools.required_role(Tools.DeleteCandidate) == :admin
  end

  test "for_role hides admin tools from members and keeps them for admins" do
    all = Tools.all()

    member_tools = Tools.for_role(all, "member")
    admin_tools = Tools.for_role(all, "admin")

    refute Tools.DeleteJob in member_tools
    refute Tools.DeleteCandidate in member_tools
    assert Tools.DeleteJob in admin_tools
    assert Tools.ListJobs in member_tools
    assert length(member_tools) < length(admin_tools)
  end

  test "authorize denies admin tools for members and allows any tools" do
    assert :ok = Tools.authorize(Tools.ListJobs, %{role: "member"})
    assert {:error, :unauthorized} = Tools.authorize(Tools.DeleteJob, %{role: "member"})
    assert :ok = Tools.authorize(Tools.DeleteJob, %{role: "admin"})
  end

  test "validate rejects wrong argument types and accepts valid ones" do
    assert {:ok, %{"job_id" => "abc"}} = Tools.validate(Tools.GetJob, %{"job_id" => "abc"})
    assert {:error, message} = Tools.validate(Tools.GetJob, %{"job_id" => 123})
    assert message =~ "job_id"
    assert {:error, _} = Tools.validate(Tools.GetJob, %{})
  end

  test "validate tolerates unknown keys" do
    assert {:ok, %{"job_id" => "abc"}} =
             Tools.validate(Tools.GetJob, %{"job_id" => "abc", "extra" => true})
  end

  test "destructive flag only on writes" do
    refute ListJobs.destructive?()
    refute ExplainPage.destructive?()
    refute ProposeFormFill.destructive?()
    assert CreateJob.destructive?()
    assert UpdateJob.destructive?()
    assert DeleteJob.destructive?()
  end

  test "list_jobs is scoped to the ctx tenant" do
    {tenant_a, _} = tenant_with_user()
    {tenant_b, _} = tenant_with_user()

    create_job(tenant_a, %{title: "A job"})
    create_job(tenant_b, %{title: "B job"})
    Repo.put_tenant_id(tenant_a.id)

    {:ok, jobs} = ListJobs.run(%{}, %{tenant_id: tenant_a.id})

    assert Enum.map(jobs, & &1["title"]) == ["A job"]
  end

  test "update/delete reject a cross-tenant job id" do
    {tenant_a, _} = tenant_with_user()
    {tenant_b, _} = tenant_with_user()
    job_b = create_job(tenant_b, %{title: "B job"})
    Repo.put_tenant_id(tenant_a.id)

    assert {:error, "job not found"} =
             DeleteJob.run(%{"job_id" => job_b.id}, %{tenant_id: tenant_a.id, role: "admin"})

    assert {:error, "job not found"} =
             UpdateJob.run(
               %{"job_id" => job_b.id, "title" => "Hacked"},
               %{tenant_id: tenant_a.id}
             )

    Repo.put_tenant_id(tenant_b.id)
    assert Repo.get!(Job, job_b.id).title == "B job"
  end

  test "create_job uses tenant_id from ctx, never from args" do
    {tenant_a, user} = tenant_with_user()
    {tenant_b, _} = tenant_with_user()
    Repo.put_tenant_id(tenant_a.id)

    {:ok, job} =
      CreateJob.run(
        %{"title" => "New", "description" => "d", "tenant_id" => tenant_b.id},
        %{tenant_id: tenant_a.id, user: user}
      )

    assert Repo.get!(Job, job["id"]).tenant_id == tenant_a.id
  end
end
