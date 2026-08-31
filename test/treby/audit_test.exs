defmodule Treby.AuditTest do
  use Treby.DataCase, async: true

  alias Treby.{Audit, Tenants, Repo}
  alias Treby.Accounts.User
  alias Treby.Audit.AuditEvent

  defp setup_tenant do
    {:ok, tenant} =
      Tenants.create_tenant(%{
        name: "Audit Corp #{System.unique_integer([:positive])}",
        slug: "audit-#{System.unique_integer([:positive])}"
      })

    {:ok, user} =
      tenant
      |> Ecto.build_assoc(:users)
      |> User.changeset(%{
        email: "audit-#{System.unique_integer([:positive])}@test.com",
        password: "password123",
        name: "Audit Admin",
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

  describe "log_event/4" do
    test "creates audit event with required fields" do
      {tenant, user} = setup_tenant()

      assert {:ok, %AuditEvent{} = event} =
               Audit.log_event("job.created", "job", Ecto.UUID.generate(), %{
                 tenant_id: tenant.id,
                 actor_id: user.id,
                 metadata: %{after: %{title: "Engineer"}}
               })

      assert event.tenant_id == tenant.id
      assert event.actor_id == user.id
      assert event.action == "job.created"
      assert event.entity_type == "job"
    end

    test "requires tenant_id" do
      assert {:error, changeset} =
               Audit.log_event("job.created", "job", Ecto.UUID.generate(), %{})

      assert errors_on(changeset)[:tenant_id]
    end

    test "sanitizes sensitive keys" do
      {tenant, _user} = setup_tenant()

      {:ok, event} =
        Audit.log_event("job.updated", "job", Ecto.UUID.generate(), %{
          tenant_id: tenant.id,
          metadata: %{password: "secret", token: "abc", title: "ok"}
        })

      refute Map.has_key?(event.metadata, "password")
      refute Map.has_key?(event.metadata, :password)
      assert event.metadata["title"] == "ok" or event.metadata[:title] == "ok"
    end
  end

  describe "list_events/2 tenant isolation" do
    test "only returns events for given tenant" do
      {t1, _} = setup_tenant()
      {t2, _} = setup_tenant()

      {:ok, _} =
        Audit.log_event("job.created", "job", Ecto.UUID.generate(), %{
          tenant_id: t1.id,
          metadata: %{}
        })

      {:ok, _} =
        Audit.log_event("job.created", "job", Ecto.UUID.generate(), %{
          tenant_id: t2.id,
          metadata: %{}
        })

      {events1, _} = Audit.list_events(t1.id, [])
      {events2, _} = Audit.list_events(t2.id, [])

      assert Enum.all?(events1, &(&1.tenant_id == t1.id))
      assert Enum.all?(events2, &(&1.tenant_id == t2.id))
      assert events1 != []
      assert events2 != []
    end

    test "filters by action prefix" do
      {tenant, _} = setup_tenant()

      {:ok, _} =
        Audit.log_event("job.created", "job", Ecto.UUID.generate(), %{tenant_id: tenant.id})

      {:ok, _} =
        Audit.log_event("candidate.created", "candidate", Ecto.UUID.generate(), %{
          tenant_id: tenant.id
        })

      {events, _} = Audit.list_events(tenant.id, action: "job.")
      assert Enum.count(events) == 1
      assert hd(events).action == "job.created"
    end

    test "pagination" do
      {tenant, _} = setup_tenant()
      # clear existing audit events for this tenant to make pagination deterministic
      Repo.delete_all(from a in Treby.Audit.AuditEvent, where: a.tenant_id == ^tenant.id)

      for _ <- 1..3,
          do: Audit.log_event("job.created", "job", Ecto.UUID.generate(), %{tenant_id: tenant.id})

      {p1, _} = Audit.list_events(tenant.id, page: 1, page_size: 2)
      {p2, _} = Audit.list_events(tenant.id, page: 2, page_size: 2)
      assert Enum.count(p1) == 2
      assert Enum.count(p2) == 1
    end
  end

  describe "log_event_multi/6 atomicity" do
    test "inserts via Multi" do
      {tenant, _} = setup_tenant()

      multi =
        Ecto.Multi.new()
        |> Audit.log_event_multi(:audit, "test.action", "job", Ecto.UUID.generate(), %{
          tenant_id: tenant.id
        })

      assert {:ok, %{audit: %AuditEvent{}}} = Repo.transaction(multi)
    end
  end

  describe "immutability" do
    test "audit_events has no updated_at" do
      {tenant, _} = setup_tenant()

      {:ok, event} =
        Audit.log_event("job.created", "job", Ecto.UUID.generate(), %{tenant_id: tenant.id})

      assert Map.has_key?(event, :inserted_at)
      refute Map.has_key?(event, :updated_at) and not is_nil(Map.get(event, :updated_at))
    end
  end
end
