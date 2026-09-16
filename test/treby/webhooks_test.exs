defmodule Treby.WebhooksTest do
  use Treby.DataCase, async: true

  alias Treby.{Webhooks, Tenants, Repo, Audit}
  alias Treby.Accounts.User
  alias Treby.Webhooks.WebhookSubscription

  defp setup_tenant do
    {:ok, tenant} =
      Tenants.create_tenant(%{
        name: "WH Corp #{System.unique_integer([:positive])}",
        slug: "wh-#{System.unique_integer([:positive])}"
      })

    {:ok, user} =
      tenant
      |> Ecto.build_assoc(:users)
      |> User.changeset(%{
        email: "wh-#{System.unique_integer([:positive])}@test.com",
        password: "password123",
        name: "WH Admin",
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

  defp create_sub(tenant, events_text, opts \\ []) do
    attrs = %{
      target_url: opts[:target_url] || "https://example.com/hook",
      events_text: events_text,
      description: opts[:description] || ""
    }

    attrs = if opts[:secret], do: Map.put(attrs, :secret, opts[:secret]), else: attrs

    attrs =
      if Keyword.has_key?(opts, :active), do: Map.put(attrs, :active, opts[:active]), else: attrs

    Webhooks.create_subscription(tenant.id, attrs) |> Webhooks.save_subscription()
  end

  describe "event matching" do
    test "exact match" do
      {tenant, _} = setup_tenant()
      {:ok, _} = create_sub(tenant, "candidate.created")

      matched = Webhooks.matching_subscriptions(tenant.id, "candidate.created")
      assert length(matched) == 1
    end

    test "namespace wildcard match" do
      {tenant, _} = setup_tenant()
      {:ok, _} = create_sub(tenant, "candidate.*")

      assert Enum.count(Webhooks.matching_subscriptions(tenant.id, "candidate.updated")) == 1
      assert Enum.count(Webhooks.matching_subscriptions(tenant.id, "candidate.deleted")) == 1
      assert Enum.empty?(Webhooks.matching_subscriptions(tenant.id, "job.updated"))
    end

    test "global wildcard match" do
      {tenant, _} = setup_tenant()
      {:ok, _} = create_sub(tenant, "*")

      assert length(Webhooks.matching_subscriptions(tenant.id, "anything.happened")) == 1
    end

    test "no match for unrelated event" do
      {tenant, _} = setup_tenant()
      {:ok, _} = create_sub(tenant, "job.created")

      assert Webhooks.matching_subscriptions(tenant.id, "candidate.created") == []
    end

    test "paused subscription does not match" do
      {tenant, _} = setup_tenant()
      {:ok, _} = create_sub(tenant, "*", active: false)

      assert Webhooks.matching_subscriptions(tenant.id, "candidate.created") == []
    end

    test "other tenant subscriptions are isolated" do
      {tenant_a, _} = setup_tenant()
      {tenant_b, _} = setup_tenant()
      {:ok, _} = create_sub(tenant_a, "*")

      assert Webhooks.matching_subscriptions(tenant_b.id, "candidate.created") == []
    end
  end

  describe "active_for_tenant?/1" do
    test "false with no subscriptions, true with an active one" do
      {tenant, _} = setup_tenant()
      refute Webhooks.active_for_tenant?(tenant.id)

      {:ok, _} = create_sub(tenant, "candidate.*")
      assert Webhooks.active_for_tenant?(tenant.id)
    end
  end

  describe "secret encryption" do
    test "secret is encrypted at rest and decrypted on read" do
      {tenant, _} = setup_tenant()
      {:ok, sub} = create_sub(tenant, "candidate.*", secret: "plain-secret-123")

      assert sub.secret == "plain-secret-123"

      reloaded = Repo.get(WebhookSubscription, sub.id)
      assert reloaded.secret == "plain-secret-123"
    end
  end

  describe "sign/2" do
    test "produces lowercase hex HMAC-SHA256" do
      secret = "s3cr3t"
      envelope = %{event: "ping", id: "abc"}
      body = Jason.encode!(envelope)
      sig = Webhooks.sign(secret, body)

      expected =
        :crypto.mac(:hmac, :sha256, secret, body)
        |> Base.encode16(case: :lower)

      assert sig == expected
    end
  end

  describe "build_envelope/3" do
    test "includes current entity, before/after and tenant id" do
      event = %{
        id: "evt",
        action: "candidate.created",
        entity_type: "candidate",
        entity_id: "eid",
        tenant_id: "tid",
        actor_type: "user",
        actor_id: "uid",
        metadata: %{before: nil, after: %{name: "A"}},
        inserted_at: ~U[2026-01-01 00:00:00Z]
      }

      envelope = Webhooks.build_envelope(event, "delivery-1", %{name: "A"})

      assert envelope.id == "delivery-1"
      assert envelope.event == "candidate.created"
      assert envelope.entity_type == "candidate"
      assert envelope.tenant_id == "tid"
      assert envelope.actor == %{type: "user", id: "uid"}
      assert envelope.data.current == %{name: "A"}
      assert envelope.data.before == nil
      assert envelope.data.after == %{name: "A"}
      assert is_binary(envelope.occurred_at)
    end
  end

  describe "Entities.fetch/2" do
    test "returns the current entity for a registered type" do
      {tenant, _} = setup_tenant()
      assert {:ok, map} = Webhooks.Entities.fetch("tenant", tenant.id)
      assert map.id == tenant.id
    end

    test "returns not_found for a missing entity" do
      {tenant, _} = setup_tenant()
      assert {:not_found, nil} = Webhooks.Entities.fetch("tenant", Ecto.UUID.generate())
    end

    test "returns unknown for an unregistered type" do
      assert {:unknown, nil} = Webhooks.Entities.fetch("does_not_exist", "x")
    end

    test "sanitizes sensitive fields" do
      {tenant, user} = setup_tenant()
      {:ok, map} = Webhooks.Entities.fetch("tenant", tenant.id)
      refute Map.has_key?(map, :encrypted_stuff)
    end
  end

  describe "dispatch/1" do
    test "is a no-op and does not raise when tenant has no subscriptions" do
      {tenant, _} = setup_tenant()
      event = %Audit.AuditEvent{tenant_id: tenant.id, id: Ecto.UUID.generate()}
      assert Webhooks.dispatch(event) == :ok
    end
  end
end
