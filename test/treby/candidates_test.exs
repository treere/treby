defmodule Treby.CandidatesTest do
  use Treby.DataCase, async: true

  alias Ecto.Adapters.SQL.Sandbox
  alias Treby.{Tenants, Candidates, Repo}
  alias Treby.Accounts.User
  alias Treby.Candidates.Candidate

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

  describe "create_or_find/2 concurrency" do
    test "parallel creates with the same email produce a single candidate" do
      {tenant, _user} = setup_tenant()
      test_pid = self()
      email = "race-#{System.unique_integer([:positive])}@example.com"

      results =
        1..10
        |> Task.async_stream(
          fn i ->
            Sandbox.allow(Repo, test_pid, self())

            Candidates.create_or_find(tenant.id, %{name: "Racer #{i}", email: email})
          end,
          max_concurrency: 10,
          timeout: 30_000
        )
        |> Enum.map(fn {:ok, result} -> result end)

      assert Enum.all?(results, &match?({:ok, _}, &1))

      ids = Enum.map(results, fn {:ok, candidate} -> candidate.id end) |> Enum.uniq()
      assert length(ids) == 1

      count =
        Candidate
        |> where([c], c.tenant_id == ^tenant.id and fragment("lower(?)", c.email) == ^email)
        |> Repo.aggregate(:count)

      assert count == 1
    end
  end

  describe "search with LIKE wildcards" do
    test "% matches literally, not as a wildcard" do
      {tenant, _user} = setup_tenant()

      {:ok, _} =
        tenant
        |> Ecto.build_assoc(:candidates)
        |> Candidate.changeset(%{name: "Hundred Percent", email: "a@example.com"})
        |> Repo.insert()

      assert Candidates.list_candidates(tenant.id, %{search: "%"}) == []
    end

    test "_ matches literally, not as a single-char wildcard" do
      {tenant, _user} = setup_tenant()

      {:ok, _} =
        tenant
        |> Ecto.build_assoc(:candidates)
        |> Candidate.changeset(%{name: "Bob", email: "bob@example.com"})
        |> Repo.insert()

      assert Candidates.list_candidates(tenant.id, %{search: "b_b"}) == []
    end
  end

  describe "list_candidates/2 pagination" do
    test "out-of-range page clamps to the last page" do
      {tenant, _user} = setup_tenant()

      for i <- 1..3 do
        {:ok, _} =
          tenant
          |> Ecto.build_assoc(:candidates)
          |> Candidate.changeset(%{name: "Clamped #{i}", email: "clamped-#{i}@example.com"})
          |> Repo.insert()
      end

      {entries, page_info} = Candidates.list_candidates(tenant.id, %{page: 999})
      assert page_info.page == 1
      assert page_info.total_count == 3
      assert length(entries) == 3
    end

    test "page 2 returns distinct rows" do
      {tenant, _user} = setup_tenant()

      for i <- 1..30 do
        {:ok, _} =
          tenant
          |> Ecto.build_assoc(:candidates)
          |> Candidate.changeset(%{
            name: "Paged #{String.pad_leading(to_string(i), 2, "0")}",
            email: "paged-#{i}@example.com"
          })
          |> Repo.insert()
      end

      {page1, info1} = Candidates.list_candidates(tenant.id, %{page: 1, page_size: 25})
      {page2, info2} = Candidates.list_candidates(tenant.id, %{page: 2, page_size: 25})

      assert info1.total_count == 30 and info2.total_count == 30
      assert length(page1) == 25 and length(page2) == 5
      assert MapSet.disjoint?(MapSet.new(page1, & &1.id), MapSet.new(page2, & &1.id))
    end

    test "leading-wildcard search uses the trigram index" do
      import Ecto.Query

      {_tenant, _user} = setup_tenant()
      pattern = "%#{Treby.Candidates.Queries.escape_like("smith")}%"

      # Name-only shape: proves the trigram operator class serves the
      # pattern (combined tenant+search plans are cost-based and may prefer
      # the tenant btree on small tables).
      query = Candidate |> where([c], ilike(c.name, ^pattern))

      # Tiny tables invite seq scans; disable them so the plan reveals
      # index usability.
      Repo.query!("SET LOCAL enable_seqscan = off")
      plan = Ecto.Adapters.SQL.explain(Repo, :all, query)

      assert is_binary(plan)
      assert plan =~ "candidates_name_trgm_idx"
    end
  end

  describe "tenant_has_candidates?/1" do
    test "returns false when tenant has no candidates" do
      {tenant, _user} = setup_tenant()
      refute Candidates.tenant_has_candidates?(tenant.id)
    end

    test "returns true when tenant has candidates" do
      {tenant, _user} = setup_tenant()

      {:ok, _candidate} =
        tenant
        |> Ecto.build_assoc(:candidates)
        |> Candidate.changeset(%{
          name: "John Doe",
          email: "john@example.com"
        })
        |> Repo.insert()

      assert Candidates.tenant_has_candidates?(tenant.id)
    end
  end
end
