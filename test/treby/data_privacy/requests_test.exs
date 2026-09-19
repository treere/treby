defmodule Treby.DataPrivacy.RequestsTest do
  use Treby.DataCase, async: true

  alias Treby.DataPrivacy.Requests
  alias Treby.{Tenants, Repo}
  alias Treby.Accounts.User

  defp setup_tenant(suffix \\ nil) do
    suffix = suffix || System.unique_integer([:positive])

    {:ok, tenant} =
      Tenants.create_tenant(%{
        name: "Data & Privacy Corp #{suffix}",
        slug: "data-privacy-#{suffix}"
      })

    {:ok, user} =
      tenant
      |> Ecto.build_assoc(:users)
      |> User.changeset(%{
        email: "data-privacy-#{suffix}@test.com",
        password: "password123",
        name: "Data & Privacy Admin",
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

  describe "create_request/1" do
    test "creates export request and enqueues worker" do
      {tenant, user} = setup_tenant()

      assert {:ok, req} =
               Requests.create_request(%{
                 tenant_id: tenant.id,
                 requester_id: user.id,
                 type: "export",
                 scope: "user",
                 status: "pending"
               })

      assert req.tenant_id == tenant.id
      assert req.type == "export"
    end

    test "rejects duplicate pending" do
      {tenant, user} = setup_tenant()

      {:ok, _} =
        Repo.insert(%Treby.DataPrivacy.DataPrivacyRequest{
          tenant_id: tenant.id,
          requester_id: user.id,
          type: "export",
          scope: "user",
          status: "pending",
          metadata: %{}
        })

      attrs = %{
        tenant_id: tenant.id,
        requester_id: user.id,
        type: "export",
        scope: "user",
        status: "pending",
        metadata: %{}
      }

      assert {:error, changeset} = Requests.create_request(attrs)

      assert changeset.errors[:tenant_id] || changeset.errors[:requester_id] ||
               changeset.errors[:type]
    end

    test "tenant isolation" do
      {t1, u1} = setup_tenant()
      {t2, u2} = setup_tenant()

      {:ok, _} =
        Requests.create_request(%{
          tenant_id: t1.id,
          requester_id: u1.id,
          type: "export",
          scope: "user",
          status: "pending"
        })

      assert Requests.list_requests(t1.id) |> length() == 1
      assert Requests.list_requests(t2.id) |> length() == 0
      # u2 in t2 can create own
      {:ok, _} =
        Requests.create_request(%{
          tenant_id: t2.id,
          requester_id: u2.id,
          type: "export",
          scope: "user",
          status: "pending"
        })

      assert Requests.list_requests(t2.id) |> length() == 1
    end

    test "erasure requires no s3_key" do
      {tenant, user} = setup_tenant()

      assert {:error, changeset} =
               Requests.create_request(%{
                 tenant_id: tenant.id,
                 requester_id: user.id,
                 type: "erasure",
                 scope: "user",
                 status: "pending",
                 s3_key: "foo"
               })

      assert changeset.errors[:s3_key]
    end
  end

  describe "cancel/1" do
    test "cancels pending" do
      {tenant, user} = setup_tenant()

      {:ok, req} =
        Repo.insert(%Treby.DataPrivacy.DataPrivacyRequest{
          tenant_id: tenant.id,
          requester_id: user.id,
          type: "erasure",
          scope: "user",
          status: "pending",
          metadata: %{"grace_until" => DateTime.utc_now() |> DateTime.to_iso8601()}
        })

      assert {:ok, cancelled} = Requests.cancel(req)
      assert cancelled.status == "cancelled"
    end

    test "cannot cancel ready export" do
      {tenant, user} = setup_tenant()

      {:ok, req} =
        Repo.insert(%Treby.DataPrivacy.DataPrivacyRequest{
          tenant_id: tenant.id,
          requester_id: user.id,
          type: "export",
          scope: "user",
          status: "pending",
          metadata: %{}
        })

      {:ok, ready} =
        Requests.transition(req, "ready", %{
          s3_key: "#{tenant.id}/data-privacy-exports/#{req.id}.zip",
          expires_at: DateTime.add(DateTime.utc_now(), 3600, :second)
        })

      assert {:error, :not_cancellable} = Requests.cancel(ready)
    end
  end

  describe "expire_ready/0" do
    test "expires ready past expiry" do
      {tenant, user} = setup_tenant()

      {:ok, req} =
        Repo.insert(%Treby.DataPrivacy.DataPrivacyRequest{
          tenant_id: tenant.id,
          requester_id: user.id,
          type: "export",
          scope: "user",
          status: "pending",
          metadata: %{}
        })

      past = DateTime.add(DateTime.utc_now(), -3600, :second)

      {:ok, ready} =
        Requests.transition(req, "ready", %{
          s3_key: "#{tenant.id}/data-privacy-exports/#{req.id}.zip",
          expires_at: past
        })

      Requests.expire_ready()
      expired = Repo.get!(Treby.DataPrivacy.DataPrivacyRequest, ready.id)
      assert expired.status == "expired"
    end
  end
end
