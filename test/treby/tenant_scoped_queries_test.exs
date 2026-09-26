defmodule Treby.TenantScopedQueriesTest do
  use Treby.DataCase, async: false

  alias Treby.{Jobs, Repo, Tenants}

  defp tenant_with_job(suffix, role \\ "recruiter") do
    {:ok, tenant} = Tenants.create_tenant(%{name: "TSQ #{suffix}", slug: "tsq-#{suffix}"})

    {:ok, job} =
      Jobs.create_job(%{"title" => "J #{suffix}", "description" => "D", "tenant_id" => tenant.id})

    {tenant, job, role}
  end

  test "field-less schema queries pass through without tenant" do
    Repo.put_tenant_id(nil)
    assert is_list(Repo.all(Treby.Tenants.Tenant))
  end

  test "unscoped tenant-field query raises" do
    Repo.put_tenant_id(nil)

    assert_raise RuntimeError, ~r/expected tenant_id/, fn ->
      Repo.all(Treby.Jobs.Job)
    end
  end

  test "cross-tenant rows invisible, explicit option wins" do
    {t1, j1, _} = tenant_with_job("a-#{System.unique_integer([:positive])}")
    {t2, j2, _} = tenant_with_job("b-#{System.unique_integer([:positive])}")

    Repo.put_tenant_id(t1.id)
    assert [%{id: id1}] = Repo.all(Treby.Jobs.Job) |> Enum.filter(&(&1.id in [j1.id, j2.id]))
    assert id1 == j1.id

    assert [%{id: id2}] =
             Treby.Jobs.Job
             |> Ecto.Query.where(tenant_id: ^t2.id)
             |> Repo.all(tenant_id: t2.id)
             |> Enum.filter(&(&1.id in [j1.id, j2.id]))

    assert id2 == j2.id
  end

  test "skip_tenant_id bypasses scoping" do
    {_, j1, _} = tenant_with_job("c-#{System.unique_integer([:positive])}")
    {_, j2, _} = tenant_with_job("d-#{System.unique_integer([:positive])}")

    Repo.put_tenant_id(nil)
    ids = Repo.all(Treby.Jobs.Job, skip_tenant_id: true) |> Enum.map(& &1.id)
    assert j1.id in ids and j2.id in ids
  end
end
