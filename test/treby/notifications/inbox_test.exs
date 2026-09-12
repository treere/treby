defmodule Treby.Notifications.InboxTest do
  use Treby.DataCase, async: true

  alias Treby.Notifications.Inbox
  alias Treby.Tenants
  alias Treby.Accounts.User
  alias Treby.Repo

  defp setup_tenant_with_members(count \\ 2) do
    {:ok, tenant} =
      Tenants.create_tenant(%{
        name: "Inbox Test #{System.unique_integer([:positive])}",
        slug: "inbox-#{System.unique_integer([:positive])}"
      })

    users =
      Enum.map(1..count, fn i ->
        {:ok, user} =
          tenant
          |> Ecto.build_assoc(:users)
          |> User.changeset(%{
            email: "inbox#{i}-#{System.unique_integer([:positive])}@test.com",
            password: "password123",
            name: "User #{i}",
            role: "member"
          })
          |> Repo.insert()

        {:ok, _} =
          Treby.Memberships.create_membership(%{
            user_id: user.id,
            tenant_id: tenant.id,
            role: "member"
          })

        user
      end)

    {tenant, users}
  end

  describe "create_for_tenant/4" do
    test "fans out to all tenant members" do
      {tenant, users} = setup_tenant_with_members(2)

      {:ok, notifications} =
        Inbox.create_for_tenant(tenant.id, %{
          type: "new_application",
          title: "New app",
          body: "body",
          link: "/app/candidates/1"
        })

      assert length(notifications) == 2
      recipient_ids = Enum.map(notifications, & &1.recipient_id) |> Enum.sort()
      assert recipient_ids == Enum.map(users, & &1.id) |> Enum.sort()
    end

    test "respects inbox preference" do
      {tenant, _users} = setup_tenant_with_members(1)

      {:ok, tenant} =
        Treby.Notifications.set_notification_preference(tenant, "new_application", %{
          "email" => true,
          "inbox" => false
        })

      # Need reload tenant after set
      tenant = Repo.get!(Tenants.Tenant, tenant.id)

      {:ok, notifications} =
        Inbox.create_for_tenant(tenant.id, %{type: "new_application", title: "x", body: "y"})

      assert notifications == []
    end
  end

  describe "counts/2 and list" do
    test "counts and filters" do
      {tenant, [user | _]} = setup_tenant_with_members(1)

      {:ok, _} =
        Inbox.create_for_tenant(tenant.id, %{
          type: "new_application",
          title: "Hello world",
          body: "body"
        })

      %{total: total, unread: unread} = Inbox.counts(user.id, tenant.id)
      assert total == 1
      assert unread == 1

      all = Inbox.list_for_user(user.id, tenant.id, filter: :all)
      assert length(all) == 1

      unread_list = Inbox.list_for_user(user.id, tenant.id, filter: :unread)
      assert length(unread_list) == 1

      # search
      searched = Inbox.list_for_user(user.id, tenant.id, search: "Hello")
      assert length(searched) == 1

      not_found = Inbox.list_for_user(user.id, tenant.id, search: "nomatch")
      assert length(not_found) == 0
    end

    test "mark_read and mark_all_read" do
      {tenant, [user | _]} = setup_tenant_with_members(1)
      {:ok, [n]} = Inbox.create_for_tenant(tenant.id, %{type: "new_application", title: "t"})
      assert is_nil(n.read_at)
      {:ok, _} = Inbox.mark_read(n.id, user.id, tenant.id)
      %{unread: unread} = Inbox.counts(user.id, tenant.id)
      assert unread == 0

      {:ok, _} = Inbox.create_for_tenant(tenant.id, %{type: "new_application", title: "t2"})
      {:ok, _} = Inbox.create_for_tenant(tenant.id, %{type: "new_application", title: "t3"})
      %{unread: unread2} = Inbox.counts(user.id, tenant.id)
      assert unread2 == 2
      {:ok, count} = Inbox.mark_all_read(user.id, tenant.id)
      assert count == 2
      %{unread: unread3} = Inbox.counts(user.id, tenant.id)
      assert unread3 == 0
    end

    test "tenant isolation" do
      {tenant1, [user1 | _]} = setup_tenant_with_members(1)
      {tenant2, [user2 | _]} = setup_tenant_with_members(1)
      {:ok, _} = Inbox.create_for_tenant(tenant1.id, %{type: "new_application", title: "t"})
      assert length(Inbox.list_for_user(user1.id, tenant1.id)) == 1
      assert length(Inbox.list_for_user(user2.id, tenant2.id)) == 0
      assert length(Inbox.list_for_user(user1.id, tenant2.id)) == 0
    end
  end

  describe "retention" do
    test "delete_read_older_than respects unread" do
      {tenant, [user | _]} = setup_tenant_with_members(1)
      {:ok, [n]} = Inbox.create_for_tenant(tenant.id, %{type: "new_application", title: "t"})
      {:ok, _} = Inbox.mark_read(n.id, user.id, tenant.id)
      # artificially set read_at to old
      old = DateTime.add(DateTime.utc_now(), -40 * 24 * 60 * 60, :second)
      Repo.update_all(Treby.Notifications.Notification, set: [read_at: old])
      {:ok, deleted} = Inbox.delete_read_older_than(tenant.id, 30)
      assert deleted == 1
      assert Inbox.counts(user.id, tenant.id).total == 0

      # unread never deleted
      {:ok, [_n2]} = Inbox.create_for_tenant(tenant.id, %{type: "new_application", title: "t2"})
      {:ok, deleted2} = Inbox.delete_read_older_than(tenant.id, 0)
      assert deleted2 == 0
    end
  end
end
