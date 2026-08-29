defmodule Treby.AvailabilityTest do
  use Treby.DataCase, async: true

  alias Treby.Availability
  alias Treby.Availability.AvailabilityRule
  alias Treby.Calendar.Providers.Treby, as: InternalCalendar
  alias Treby.GoogleApiMock

  setup do
    {:ok, tenant} = insert_tenant()
    {:ok, user} = insert_user(tenant.id)
    {:ok, tenant: tenant, user: user}
  end

  describe "list_rules_for_user/1" do
    test "returns rules for a specific user", %{user: user} do
      _other_user = insert_user(user.tenant_id) |> elem(1)

      {:ok, rule1} =
        create_rule(user.id, user.tenant_id,
          day_of_week: 1,
          start_time: ~T[09:00:00],
          end_time: ~T[17:00:00]
        )

      {:ok, rule2} =
        create_rule(user.id, user.tenant_id,
          day_of_week: 2,
          start_time: ~T[10:00:00],
          end_time: ~T[16:00:00]
        )

      rules = Availability.list_rules_for_user(user.id)
      assert length(rules) == 2
      assert Enum.map(rules, & &1.id) |> Enum.sort() == Enum.sort([rule1.id, rule2.id])
    end

    test "returns empty list for user with no rules", %{user: user} do
      assert Availability.list_rules_for_user(user.id) == []
    end
  end

  describe "create_rule/1" do
    test "creates a rule with valid attrs", %{user: user, tenant: tenant} do
      attrs = %{
        user_id: user.id,
        tenant_id: tenant.id,
        day_of_week: 1,
        start_time: ~T[09:00:00],
        end_time: ~T[17:00:00],
        timezone: "America/New_York",
        buffer_before: 15,
        buffer_after: 15
      }

      assert {:ok, %AvailabilityRule{} = rule} = Availability.create_rule(attrs)
      assert rule.day_of_week == 1
      assert rule.start_time == ~T[09:00:00]
      assert rule.end_time == ~T[17:00:00]
      assert rule.timezone == "America/New_York"
      assert rule.buffer_before == 15
      assert rule.buffer_after == 15
    end

    test "returns error with invalid attrs" do
      assert {:error, changeset} = Availability.create_rule(%{})
      assert errors_on(changeset) |> Map.has_key?(:user_id)
    end
  end

  describe "update_rule/2" do
    test "updates rule attrs", %{user: user, tenant: tenant} do
      {:ok, rule} =
        create_rule(user.id, tenant.id,
          day_of_week: 1,
          start_time: ~T[09:00:00],
          end_time: ~T[17:00:00]
        )

      assert {:ok, updated} = Availability.update_rule(rule, %{start_time: ~T[10:00:00]})
      assert updated.start_time == ~T[10:00:00]
    end
  end

  describe "delete_rule/1" do
    test "deletes the rule", %{user: user, tenant: tenant} do
      {:ok, rule} =
        create_rule(user.id, tenant.id,
          day_of_week: 1,
          start_time: ~T[09:00:00],
          end_time: ~T[17:00:00]
        )

      assert {:ok, _} = Availability.delete_rule(rule)
      assert_raise Ecto.NoResultsError, fn -> Availability.get_rule!(rule.id) end
    end
  end

  describe "compute_slots/4" do
    test "returns slots for a day with availability and no busy periods", %{
      user: user,
      tenant: tenant
    } do
      create_rule(user.id, tenant.id,
        day_of_week: Date.day_of_week(~D[2024-01-15]),
        start_time: ~T[09:00:00],
        end_time: ~T[17:00:00],
        timezone: "UTC",
        buffer_before: 0,
        buffer_after: 0
      )

      slots =
        Availability.compute_slots(user.id, %{from: ~D[2024-01-15], to: ~D[2024-01-15]})

      assert length(slots) == 16
      assert hd(slots).start == DateTime.new!(~D[2024-01-15], ~T[09:00:00], "UTC")
      assert List.last(slots).end == DateTime.new!(~D[2024-01-15], ~T[17:00:00], "UTC")
    end

    test "returns empty list for day with no availability rules", %{user: user} do
      slots =
        Availability.compute_slots(user.id, %{from: ~D[2024-01-15], to: ~D[2024-01-15]})

      assert slots == []
    end

    test "returns slots across multiple days", %{user: user, tenant: tenant} do
      create_rule(user.id, tenant.id,
        day_of_week: 1,
        start_time: ~T[09:00:00],
        end_time: ~T[12:00:00],
        timezone: "UTC",
        buffer_before: 0,
        buffer_after: 0
      )

      create_rule(user.id, tenant.id,
        day_of_week: 2,
        start_time: ~T[10:00:00],
        end_time: ~T[14:00:00],
        timezone: "UTC",
        buffer_before: 0,
        buffer_after: 0
      )

      # 2024-01-15 is Monday, 2024-01-16 is Tuesday
      slots =
        Availability.compute_slots(user.id, %{from: ~D[2024-01-15], to: ~D[2024-01-16]})

      # Monday: 6 slots (09:00-12:00), Tuesday: 8 slots (10:00-14:00)
      assert length(slots) == 14
    end

    test "handles timezone conversion correctly", %{user: user, tenant: tenant} do
      create_rule(user.id, tenant.id,
        day_of_week: Date.day_of_week(~D[2024-01-15]),
        start_time: ~T[09:00:00],
        end_time: ~T[17:00:00],
        timezone: "America/New_York",
        buffer_before: 0,
        buffer_after: 0
      )

      slots =
        Availability.compute_slots(user.id, %{from: ~D[2024-01-15], to: ~D[2024-01-15]})

      # 09:00 EST = 14:00 UTC in January
      first_slot = hd(slots)
      utc_slot = DateTime.shift_zone!(first_slot.start, "Etc/UTC")
      assert utc_slot.hour == 14
      assert utc_slot.minute == 0
    end
  end

  describe "internal calendar provider" do
    test "existing interviews are reported as busy", %{user: user, tenant: tenant} do
      start_at = DateTime.new!(~D[2024-01-15], ~T[10:00:00], "Etc/UTC")
      end_at = DateTime.new!(~D[2024-01-15], ~T[10:30:00], "Etc/UTC")
      insert_interview_event(tenant, user.id, start_at, end_at)

      {:ok, busy} =
        InternalCalendar.fetch_busy(
          user.id,
          DateTime.new!(~D[2024-01-15], ~T[00:00:00], "UTC"),
          DateTime.new!(~D[2024-01-16], ~T[00:00:00], "UTC")
        )

      assert busy == [%{start: start_at, end: end_at}]
    end

    test "cancelled interviews are not busy", %{user: user, tenant: tenant} do
      start_at = DateTime.new!(~D[2024-01-15], ~T[10:00:00], "Etc/UTC")
      end_at = DateTime.new!(~D[2024-01-15], ~T[10:30:00], "Etc/UTC")
      event = insert_interview_event(tenant, user.id, start_at, end_at)

      Treby.Repo.update!(Ecto.Changeset.change(event, %{status: "cancelled"}))

      {:ok, busy} =
        InternalCalendar.fetch_busy(
          user.id,
          DateTime.new!(~D[2024-01-15], ~T[00:00:00], "UTC"),
          DateTime.new!(~D[2024-01-16], ~T[00:00:00], "UTC")
        )

      assert busy == []
    end

    test "existing interview blocks the slot without external connection", %{
      user: user,
      tenant: tenant
    } do
      create_rule(user.id, tenant.id,
        day_of_week: Date.day_of_week(~D[2024-01-15]),
        start_time: ~T[09:00:00],
        end_time: ~T[11:00:00],
        timezone: "UTC",
        buffer_before: 0,
        buffer_after: 0
      )

      insert_interview_event(
        tenant,
        user.id,
        DateTime.new!(~D[2024-01-15], ~T[10:00:00], "Etc/UTC"),
        DateTime.new!(~D[2024-01-15], ~T[10:30:00], "Etc/UTC")
      )

      slots = Availability.compute_slots(user.id, %{from: ~D[2024-01-15], to: ~D[2024-01-15]})

      slot_starts = Enum.map(slots, & &1.start)

      refute DateTime.new!(~D[2024-01-15], ~T[10:00:00], "Etc/UTC") in slot_starts
      assert DateTime.new!(~D[2024-01-15], ~T[09:00:00], "UTC") in slot_starts
    end
  end

  describe "external provider aggregation" do
    test "busy from internal and external providers is all excluded", %{
      user: user,
      tenant: tenant
    } do
      create_rule(user.id, tenant.id,
        day_of_week: Date.day_of_week(~D[2024-01-15]),
        start_time: ~T[09:00:00],
        end_time: ~T[15:00:00],
        timezone: "UTC",
        buffer_before: 0,
        buffer_after: 0
      )

      insert_interview_event(
        tenant,
        user.id,
        DateTime.new!(~D[2024-01-15], ~T[10:00:00], "Etc/UTC"),
        DateTime.new!(~D[2024-01-15], ~T[10:30:00], "Etc/UTC")
      )

      {:ok, _} =
        Treby.Calendar.connect_google_user(user.id, tenant.id, %{
          access_token: "access",
          refresh_token: "refresh",
          expires_at: DateTime.utc_now() |> DateTime.add(1, :hour),
          email: "user@gmail.com"
        })

      GoogleApiMock.stub_free_busy([
        %{
          "start" => "2024-01-15T14:00:00Z",
          "end" => "2024-01-15T14:30:00Z"
        }
      ])

      slots = Availability.compute_slots(user.id, %{from: ~D[2024-01-15], to: ~D[2024-01-15]})

      slot_starts = Enum.map(slots, & &1.start)

      refute DateTime.new!(~D[2024-01-15], ~T[10:00:00], "Etc/UTC") in slot_starts
      refute DateTime.new!(~D[2024-01-15], ~T[14:00:00], "UTC") in slot_starts
      assert DateTime.new!(~D[2024-01-15], ~T[09:00:00], "UTC") in slot_starts
    end

    test "provider error blocks slot computation", %{user: user, tenant: tenant} do
      create_rule(user.id, tenant.id,
        day_of_week: Date.day_of_week(~D[2024-01-15]),
        start_time: ~T[09:00:00],
        end_time: ~T[11:00:00],
        timezone: "UTC",
        buffer_before: 0,
        buffer_after: 0
      )

      {:ok, _} =
        Treby.Calendar.connect_google_user(user.id, tenant.id, %{
          access_token: "access",
          refresh_token: "refresh",
          expires_at: DateTime.utc_now() |> DateTime.add(-1, :hour),
          email: "user@gmail.com"
        })

      GoogleApiMock.stub_token_error(500, %{"error" => "boom"})

      assert {:error, {:calendar_error, {"google", {:refresh_failed, resp}}}} =
               Availability.compute_slots(user.id, %{from: ~D[2024-01-15], to: ~D[2024-01-15]})

      assert resp["error"] == "boom"
    end
  end

  defp insert_tenant do
    Treby.Repo.insert!(%Treby.Tenants.Tenant{
      name: "Test Tenant",
      slug: "test-#{System.unique_integer([:positive])}"
    })
    |> then(&{:ok, &1})
  end

  defp insert_user(tenant_id) do
    Treby.Repo.insert!(%Treby.Accounts.User{
      name: "Test User",
      email: "test-#{System.unique_integer([:positive])}@example.com",
      password_hash: Bcrypt.hash_pwd_salt("password123456"),
      tenant_id: tenant_id
    })
    |> then(&{:ok, &1})
  end

  defp create_rule(user_id, tenant_id, attrs) do
    default_attrs = %{
      user_id: user_id,
      tenant_id: tenant_id,
      timezone: "UTC",
      buffer_before: 15,
      buffer_after: 15
    }

    Availability.create_rule(Map.merge(default_attrs, Map.new(attrs)))
  end

  defp insert_interview_event(tenant, examiner_id, start_at, end_at) do
    pipeline_id =
      case Treby.Pipeline.default_pipeline_id(tenant.id) do
        nil ->
          Treby.Pipeline.create_default_pipeline_stages(tenant)
          Treby.Pipeline.default_pipeline_id(tenant.id)

        id ->
          id
      end

    stage =
      Treby.Repo.one!(
        from s in Treby.Pipeline.PipelineStage,
          where: s.pipeline_id == ^pipeline_id,
          limit: 1
      )

    {:ok, job} =
      %Treby.Jobs.Job{}
      |> Ecto.Changeset.change(%{
        title: "Test Job",
        description: "A test job",
        tenant_id: tenant.id,
        pipeline_id: pipeline_id
      })
      |> Treby.Repo.insert()

    {:ok, candidate} =
      %Treby.Candidates.Candidate{}
      |> Ecto.Changeset.change(%{
        name: "Test Candidate",
        email: "candidate-#{System.unique_integer([:positive])}@example.com",
        tenant_id: tenant.id
      })
      |> Treby.Repo.insert()

    {:ok, app} =
      %Treby.Pipeline.Application{}
      |> Ecto.Changeset.change(%{
        job_id: job.id,
        candidate_id: candidate.id,
        pipeline_stage_id: stage.id,
        tenant_id: tenant.id,
        applied_at: DateTime.utc_now() |> DateTime.truncate(:second)
      })
      |> Treby.Repo.insert()

    {:ok, event} =
      %Treby.Interviews.InterviewEvent{}
      |> Ecto.Changeset.change(%{
        start_at_utc: start_at,
        end_at_utc: end_at,
        duration_minutes: 30,
        application_id: app.id,
        tenant_id: tenant.id
      })
      |> Treby.Repo.insert()

    Treby.Repo.insert!(%Treby.Interviews.EventExaminer{
      interview_event_id: event.id,
      user_id: examiner_id
    })

    event
  end
end
