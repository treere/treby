defmodule Treby.CandidatesMergeTest do
  use Treby.DataCase, async: true

  alias Treby.{Tenants, Repo, Pipeline, Candidates, Activities, CsvImport}
  alias Treby.Accounts.User
  alias Treby.Candidates.{Candidate, MergeLog}
  alias Treby.Candidates.Duplicates

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

    {:ok, job} =
      Treby.Jobs.create_job(%{
        tenant_id: tenant.id,
        title: "Engineer",
        description: "Backend engineer"
      })

    {:ok, pipeline} =
      Pipeline.create_pipeline(%{name: "Default", tenant_id: tenant.id, is_default: true})

    {:ok, stage} =
      Pipeline.create_pipeline_stage(%{
        name: "Applied",
        position: 1,
        pipeline_id: pipeline.id,
        tenant_id: tenant.id,
        stage_type: "applied"
      })

    {tenant, user, job, stage}
  end

  defp create_candidate(tenant, attrs) do
    {:ok, candidate} =
      tenant
      |> Ecto.build_assoc(:candidates)
      |> Candidate.changeset(attrs)
      |> Repo.insert()

    candidate
  end

  defp create_candidate(tenant, attrs, %DateTime{} = inserted_at) do
    {:ok, candidate} =
      tenant
      |> Ecto.build_assoc(:candidates)
      |> Candidate.changeset(attrs)
      |> Ecto.Changeset.force_change(:inserted_at, inserted_at)
      |> Ecto.Changeset.force_change(:updated_at, inserted_at)
      |> Repo.insert()

    candidate
  end

  defp create_application(tenant, job, stage, candidate) do
    {:ok, application} =
      Pipeline.create_application(%{
        tenant_id: tenant.id,
        job_id: job.id,
        candidate_id: candidate.id,
        pipeline_stage_id: stage.id,
        applied_at: DateTime.utc_now()
      })

    application
  end

  defp create_conversation(tenant, candidate, application) do
    {:ok, conversation} =
      Treby.CandidatePortal.create_conversation(%{
        candidate_id: candidate.id,
        tenant_id: tenant.id,
        application_id: application.id,
        subject: "Hello",
        context: "application"
      })

    conversation.id
  end

  describe "merge_candidates/3" do
    test "reassigns applications, portal conversations and activity, and tombstones the absorbed candidate" do
      {tenant, user, job, stage} = setup_tenant()
      primary = create_candidate(tenant, %{name: "Primary Person", email: "primary@example.com"})

      absorbed =
        create_candidate(tenant, %{name: "Absorbed Person", email: "absorbed@example.com"})

      app = create_application(tenant, job, stage, absorbed)
      conversation_id = create_conversation(tenant, absorbed, app)

      {:ok, _created_event} =
        Activities.log_event("candidate_created", "candidate", absorbed.id, %{
          tenant_id: tenant.id
        })

      {:ok, %{primary: ^primary, merge_logs: [log]}} =
        Candidates.merge_candidates(primary, [absorbed], user)

      assert Repo.reload!(app).candidate_id == primary.id

      assert Repo.get!(Treby.CandidatePortal.Conversation, conversation_id).candidate_id ==
               primary.id

      assert Enum.any?(
               Activities.list_events_for_entity("candidate", primary.id, 50),
               &(&1.action == "candidates_merged")
             )

      tombstone = Repo.get!(Candidate, absorbed.id)
      assert tombstone.merged_into_id == primary.id
      refute is_nil(tombstone.merged_at)

      persisted_log = Repo.get!(MergeLog, log.id)
      assert persisted_log.primary_candidate_id == primary.id
      assert persisted_log.absorbed_candidate_id == absorbed.id
      assert persisted_log.actor_id == user.id
      assert persisted_log.application_mapping[app.id] == absorbed.id
      assert persisted_log.thread_mapping[conversation_id] == absorbed.id
    end

    test "keeps the primary untouched and no rows are deleted" do
      {tenant, user, job, stage} = setup_tenant()
      primary = create_candidate(tenant, %{name: "Primary Person", email: "primary@example.com"})

      absorbed =
        create_candidate(tenant, %{name: "Absorbed Person", email: "absorbed@example.com"})

      primary_app = create_application(tenant, job, stage, primary)
      absorbed_app = create_application(tenant, job, stage, absorbed)

      {:ok, _} = Candidates.merge_candidates(primary, [absorbed], user)

      assert Repo.reload!(primary_app).candidate_id == primary.id
      assert Repo.get!(Candidate, primary.id).merged_into_id == nil
      refute Repo.reload!(primary_app) == nil
      refute Repo.reload!(absorbed_app) == nil
    end

    test "refuses to merge tombstoned candidates" do
      {tenant, user, _job, _stage} = setup_tenant()
      primary = create_candidate(tenant, %{name: "Primary Person", email: "primary@example.com"})
      mid = create_candidate(tenant, %{name: "Middle Person", email: "mid@example.com"})
      already = create_candidate(tenant, %{name: "Already Merged", email: "already@example.com"})

      {:ok, _} = Candidates.merge_candidates(primary, [mid], user)
      tombstoned = Repo.get!(Candidate, mid.id)
      assert tombstoned.merged_into_id == primary.id

      assert {:error, :cannot_merge_tombstoned_candidate} =
               Candidates.merge_candidates(primary, [already, tombstoned], user)

      assert {:error, :primary_is_tombstoned} =
               Candidates.merge_candidates(tombstoned, [already], user)
    end

    test "refuses to merge a candidate with itself" do
      {tenant, _user, _job, _stage} = setup_tenant()
      primary = create_candidate(tenant, %{name: "Primary Person", email: "primary@example.com"})

      assert {:error, :cannot_merge_with_itself} =
               Candidates.merge_candidates(primary, [primary])
    end

    test "refuses cross-tenant merges" do
      {tenant, user, _job, _stage} = setup_tenant()
      primary = create_candidate(tenant, %{name: "Primary Person", email: "primary@example.com"})

      {:ok, other_tenant} =
        Tenants.create_tenant(%{
          name: "Other Corp",
          slug: "other-#{System.unique_integer([:positive])}"
        })

      other = create_candidate(other_tenant, %{name: "Other Person", email: "other@example.com"})

      assert {:error, :cross_tenant_merge} =
               Candidates.merge_candidates(primary, [other], user)
    end
  end

  describe "undo_merge/2" do
    test "restores entities, re-activates the absorbed candidate and deletes the merge log" do
      {tenant, user, job, stage} = setup_tenant()
      primary = create_candidate(tenant, %{name: "Primary Person", email: "primary@example.com"})

      absorbed =
        create_candidate(tenant, %{name: "Absorbed Person", email: "absorbed@example.com"})

      app = create_application(tenant, job, stage, absorbed)
      conversation_id = create_conversation(tenant, absorbed, app)

      {:ok, %{merge_logs: [log]}} = Candidates.merge_candidates(primary, [absorbed], user)
      assert Repo.get!(Candidate, absorbed.id).merged_into_id == primary.id

      {:ok, %{primary: ^primary}} =
        Candidates.undo_merge(Repo.get!(MergeLog, log.id), user)

      assert Repo.reload!(app).candidate_id == absorbed.id

      assert Repo.get!(Treby.CandidatePortal.Conversation, conversation_id).candidate_id ==
               absorbed.id

      assert Repo.get!(Candidate, absorbed.id).merged_into_id == nil
      assert Repo.get!(Candidate, absorbed.id).merged_at == nil
      assert Repo.get(MergeLog, log.id) == nil

      assert Enum.any?(
               Activities.list_events_for_entity("candidate", primary.id, 50),
               &(&1.action == "candidates_merge_undone")
             )
    end

    test "refuses to undo a merge whose primary has since been absorbed (chained merges)" do
      {tenant, user, _job, _stage} = setup_tenant()
      primary = create_candidate(tenant, %{name: "Primary Person", email: "primary@example.com"})

      absorbed =
        create_candidate(tenant, %{name: "Absorbed Person", email: "absorbed@example.com"})

      top = create_candidate(tenant, %{name: "Top Person", email: "top@example.com"})

      {:ok, %{merge_logs: [log]}} = Candidates.merge_candidates(primary, [absorbed], user)
      {:ok, _} = Candidates.merge_candidates(top, [primary], user)

      assert {:error, :primary_no_longer_mergeable} =
               Candidates.undo_merge(Repo.get!(MergeLog, log.id), user)
    end

    test "refuses to undo when the absorbed candidate is no longer tombstoned into the primary" do
      {tenant, user, _job, _stage} = setup_tenant()
      primary = create_candidate(tenant, %{name: "Primary Person", email: "primary@example.com"})

      absorbed =
        create_candidate(tenant, %{name: "Absorbed Person", email: "absorbed@example.com"})

      {:ok, %{merge_logs: [log]}} = Candidates.merge_candidates(primary, [absorbed], user)

      from(c in Candidate, where: c.id == ^absorbed.id)
      |> Repo.update_all(set: [merged_into_id: nil, merged_at: nil])

      assert {:error, :absorbed_not_in_expected_state} =
               Candidates.undo_merge(Repo.get!(MergeLog, log.id), user)
    end
  end

  describe "duplicate detection" do
    test "normalization helpers strip country prefixes and accents" do
      assert Duplicates.normalize_email("  John@Example.COM ") == "john@example.com"
      assert Duplicates.normalize_phone("+39 333 123 4567") == "3331234567"
      assert Duplicates.normalize_phone("00393331234567") == "3331234567"
      assert Duplicates.normalize_name("Renè Martìnez") == "rene martinez"
    end

    test "groups exact email duplicates with high confidence and auto_merge" do
      {tenant, _user, _job, _stage} = setup_tenant()
      _c1 = create_candidate(tenant, %{name: "First Person", email: "dup@example.com"})
      _c2 = create_candidate(tenant, %{name: "Second Person", email: " DUP@example.com "})

      [group] = Candidates.list_duplicate_groups(tenant.id)
      assert group.signal == :exact_email
      assert group.confidence == :high
      assert group.auto_merge == true
      assert length(group.candidates) == 2
    end

    test "groups normalized phone + name matches" do
      {tenant, _user, _job, _stage} = setup_tenant()

      _c1 =
        create_candidate(tenant, %{
          name: "Renè Martin",
          email: "r1@example.com",
          phone: "+39 333 123 4567"
        })

      _c2 =
        create_candidate(tenant, %{
          name: "Rene Martin",
          email: "r2@example.com",
          phone: "3331234567"
        })

      [group] = Candidates.list_duplicate_groups(tenant.id)
      assert group.signal == :phone_name
      assert group.confidence == :high
      assert group.auto_merge == false
      assert length(group.candidates) == 2
    end

    test "groups name + email local-part with medium confidence" do
      {tenant, _user, _job, _stage} = setup_tenant()
      _c1 = create_candidate(tenant, %{name: "Jane Doe", email: "jane.doe@gmail.com"})
      _c2 = create_candidate(tenant, %{name: "jane doe", email: "jane.doe@outlook.com"})

      [group] = Candidates.list_duplicate_groups(tenant.id)
      assert group.signal == :name_local_part
      assert group.confidence == :medium
      assert length(group.candidates) == 2
    end

    test "does not group candidates sharing only a name" do
      {tenant, _user, _job, _stage} = setup_tenant()
      _c1 = create_candidate(tenant, %{name: "Jane Doe", email: "jane.one@example.com"})
      _c2 = create_candidate(tenant, %{name: "Jane Doe", email: "jane.two@example.com"})

      assert Candidates.list_duplicate_groups(tenant.id) == []
    end

    test "assigns each candidate to at most one group (strongest signal wins)" do
      {tenant, _user, _job, _stage} = setup_tenant()
      _a = create_candidate(tenant, %{name: "Same Name", email: "same@example.com", phone: "111"})
      _b = create_candidate(tenant, %{name: "Same Name", email: "same@example.com", phone: "222"})
      _c = create_candidate(tenant, %{name: "Same Name", email: "same@example.com", phone: "333"})

      groups = Candidates.list_duplicate_groups(tenant.id)

      assert length(groups) == 1
      assert length(List.first(groups).candidates) == 3
    end
  end

  describe "anagrafica snapshot" do
    test "create_application stores a snapshot from the candidate when not provided" do
      {tenant, _user, job, stage} = setup_tenant()

      candidate =
        create_candidate(tenant, %{
          name: "Snapshot Person",
          email: "snap@example.com",
          phone: "12345"
        })

      app = create_application(tenant, job, stage, candidate)

      assert app.anagrafica["name"] == "Snapshot Person"
      assert app.anagrafica["email"] == "snap@example.com"
      assert app.anagrafica["phone"] == "12345"
    end

    test "explicit anagrafica is preserved" do
      {tenant, _user, job, stage} = setup_tenant()
      candidate = create_candidate(tenant, %{name: "Snapshot Person", email: "snap@example.com"})

      {:ok, app} =
        Pipeline.create_application(%{
          tenant_id: tenant.id,
          job_id: job.id,
          candidate_id: candidate.id,
          pipeline_stage_id: stage.id,
          applied_at: DateTime.utc_now(),
          anagrafica: %{"name" => "As Submitted", "email" => "submitted@example.com"}
        })

      assert app.anagrafica["name"] == "As Submitted"
      assert app.anagrafica["email"] == "submitted@example.com"
    end

    test "updating the candidate master data never mutates stored snapshots" do
      {tenant, user, job, stage} = setup_tenant()

      candidate =
        create_candidate(tenant, %{
          name: "Snapshot Person",
          email: "snap@example.com",
          phone: "12345"
        })

      app = create_application(tenant, job, stage, candidate)

      {:ok, _} =
        Candidates.update_candidate(
          candidate,
          %{name: "Changed Name", email: "new@example.com"},
          %{
            actor_id: user.id
          }
        )

      assert Repo.reload!(app).anagrafica["name"] == "Snapshot Person"
      assert Repo.reload!(app).anagrafica["email"] == "snap@example.com"
    end
  end

  describe "duplicate application flag" do
    test "is_duplicate set when a candidate re-applies to the same job" do
      {tenant, _user, job, stage} = setup_tenant()
      candidate = create_candidate(tenant, %{name: "Dup Person", email: "dup@example.com"})

      first = create_application(tenant, job, stage, candidate)
      second = create_application(tenant, job, stage, candidate)

      refute Repo.reload!(first).is_duplicate
      assert Repo.reload!(second).is_duplicate
    end

    test "recompute_duplicate_flags marks the later application as duplicate after a merge" do
      {tenant, user, job, stage} = setup_tenant()
      primary = create_candidate(tenant, %{name: "Primary Person", email: "primary@example.com"})

      absorbed =
        create_candidate(tenant, %{name: "Absorbed Person", email: "absorbed@example.com"})

      primary_app = create_application(tenant, job, stage, primary)
      absorbed_app = create_application(tenant, job, stage, absorbed)

      {:ok, _} = Candidates.merge_candidates(primary, [absorbed], user)

      assert Repo.reload!(primary_app).candidate_id == primary.id
      refute Repo.reload!(primary_app).is_duplicate
      assert Repo.reload!(absorbed_app).candidate_id == primary.id
      assert Repo.reload!(absorbed_app).is_duplicate
    end
  end

  describe "list_candidates/1" do
    test "excludes tombstoned candidates" do
      {tenant, user, _job, _stage} = setup_tenant()
      primary = create_candidate(tenant, %{name: "Primary Person", email: "primary@example.com"})

      absorbed =
        create_candidate(tenant, %{name: "Absorbed Person", email: "absorbed@example.com"})

      {:ok, _} = Candidates.merge_candidates(primary, [absorbed], user)

      ids = Enum.map(Candidates.list_candidates(tenant.id), & &1.id)
      assert primary.id in ids
      refute absorbed.id in ids
    end
  end

  describe "create_or_find/2" do
    test "is case-insensitive against stored emails" do
      {tenant, _user, _job, _stage} = setup_tenant()
      existing = create_candidate(tenant, %{name: "Alice", email: "Alice@Example.com"})

      assert {:ok, found} =
               Candidates.create_or_find(tenant.id, %{
                 name: "Alice",
                 email: "  alice@example.com  "
               })

      assert found.id == existing.id
    end

    test "does not reuse an absorbed candidate's email" do
      {tenant, user, _job, _stage} = setup_tenant()
      primary = create_candidate(tenant, %{name: "Primary Person", email: "primary@example.com"})

      absorbed =
        create_candidate(tenant, %{name: "Absorbed Person", email: "absorbed@example.com"})

      {:ok, _} = Candidates.merge_candidates(primary, [absorbed], user)

      assert {:ok, created} =
               Candidates.create_or_find(tenant.id, %{
                 name: "Fresh Person",
                 email: "absorbed@example.com"
               })

      assert created.id != absorbed.id
      assert is_nil(created.merged_into_id)
    end

    test "with no email it does not match an existing candidate and returns a validation error" do
      {tenant, _user, _job, _stage} = setup_tenant()

      _existing =
        create_candidate(tenant, %{name: "Existing Person", email: "existing@example.com"})

      assert {:error, changeset} =
               Candidates.create_or_find(tenant.id, %{name: "No Email Person"})

      refute changeset.valid?
      assert {"can't be blank", _} = changeset.errors[:email]
    end
  end

  describe "auto_merge_exact_email/2" do
    test "merges exact-email duplicates into the oldest candidate and logs the merge" do
      {tenant, user, _job, _stage} = setup_tenant()

      # Explicit, ordered `inserted_at` values: two fast sequential inserts can
      # land in the same microsecond and produce identical timestamps, which
      # would make the "oldest wins" assertion depend on arbitrary ordering.
      base = DateTime.truncate(DateTime.utc_now(), :second)
      older = create_candidate(tenant, %{name: "Older Person", email: "Same@Example.com"}, base)

      newer =
        create_candidate(
          tenant,
          %{name: "Newer Person", email: "same@example.com"},
          DateTime.add(base, 1, :second)
        )

      unrelated =
        create_candidate(tenant, %{
          name: "Frank Miller",
          email: "frank@example.com",
          phone: "555-0123"
        })

      assert %{merged: 1, skipped: 0} = Candidates.auto_merge_exact_email(tenant.id, user)

      assert Repo.get!(Candidate, older.id).merged_into_id |> is_nil()
      assert Repo.get!(Candidate, newer.id).merged_into_id == older.id
      assert Repo.get!(Candidate, unrelated.id).merged_into_id |> is_nil()

      events = Activities.list_events_for_entity("candidate", older.id, 50)
      assert Enum.any?(events, &(&1.action == "candidates_merged"))
    end

    test "leaves suggestion-only groups (phone + name) untouched" do
      {tenant, user, _job, _stage} = setup_tenant()

      c1 =
        create_candidate(tenant, %{
          name: "First Person",
          email: "first@example.com",
          phone: "555-0101"
        })

      c2 =
        create_candidate(tenant, %{
          name: "First Person",
          email: "second@example.com",
          phone: "555-0101"
        })

      assert %{merged: 0, skipped: 0} = Candidates.auto_merge_exact_email(tenant.id, user)

      assert Repo.get!(Candidate, c1.id).merged_into_id |> is_nil()
      assert Repo.get!(Candidate, c2.id).merged_into_id |> is_nil()
    end
  end

  describe "csv import candidate reuse" do
    test "reusing an absorbed candidate's email creates a new candidate" do
      {tenant, user, job, stage} = setup_tenant()
      primary = create_candidate(tenant, %{name: "Primary Person", email: "dup@example.com"})

      absorbed =
        create_candidate(tenant, %{name: "Absorbed Person", email: "absorbed@example.com"})

      {:ok, _} = Candidates.merge_candidates(primary, [absorbed], user)

      csv = "name,email,phone\nImported Person,absorbed@example.com,555-0199\n"

      {:ok, parsed} = CsvImport.parse_csv(csv)
      mapping = %{"name" => "name", "email" => "email", "phone" => "phone"}

      {:ok, results} =
        CsvImport.execute_import(parsed.rows, mapping, tenant.id, %{
          job_id: job.id,
          pipeline_stage_id: stage.id,
          source: "csv_test"
        })

      assert results.imported == 1

      [created] =
        Candidate
        |> Treby.Repo.all()
        |> Enum.filter(&(&1.email == "absorbed@example.com" and &1.id != absorbed.id))

      assert is_nil(created.merged_into_id)
      assert created.id != primary.id
    end
  end

  describe "dismiss_merge_group/3" do
    test "persists a dismissal and lists it back as a group key" do
      {tenant, _user, _job, _stage} = setup_tenant()
      group_id = "a-deterministic-group-id"

      assert {:ok, _} = Candidates.dismiss_merge_group(tenant.id, group_id)

      assert Candidates.list_dismissed_group_keys(tenant.id) == MapSet.new([group_id])
    end

    test "is idempotent for the same tenant and group" do
      {tenant, _user, _job, _stage} = setup_tenant()
      group_id = "same-group"

      assert {:ok, _} = Candidates.dismiss_merge_group(tenant.id, group_id)
      assert {:ok, _} = Candidates.dismiss_merge_group(tenant.id, group_id)

      assert MapSet.size(Candidates.list_dismissed_group_keys(tenant.id)) == 1
    end

    test "dismissals are scoped per tenant" do
      {tenant_a, _user, _job, _stage} = setup_tenant()
      {tenant_b, _user, _job, _stage} = setup_tenant()

      assert {:ok, _} = Candidates.dismiss_merge_group(tenant_a.id, "group-1")

      refute MapSet.member?(Candidates.list_dismissed_group_keys(tenant_b.id), "group-1")
    end

    test "dismissing a group hides it from duplicate suggestions" do
      {tenant, _user, _job, _stage} = setup_tenant()

      _c1 =
        create_candidate(tenant, %{
          name: "First Person",
          email: "first@example.com",
          phone: "555-0101"
        })

      _c2 =
        create_candidate(tenant, %{
          name: "First Person",
          email: "second@example.com",
          phone: "555-0101"
        })

      [group] = Candidates.list_suggestion_groups(tenant.id)

      assert {:ok, _} = Candidates.dismiss_merge_group(tenant.id, group.id)

      assert Candidates.list_suggestion_groups(tenant.id)
             |> Enum.any?(&(&1.id == group.id))
             |> Kernel.not()
    end
  end
end
