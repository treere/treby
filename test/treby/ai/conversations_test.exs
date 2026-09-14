defmodule Treby.AI.ConversationsTest do
  use Treby.DataCase, async: false

  alias Treby.AI.Conversations
  alias Treby.{Repo, Tenants}
  alias Treby.Accounts.User

  defp tenant_with_user do
    {:ok, tenant} =
      Tenants.create_tenant(%{
        name: "AI Conv #{System.unique_integer([:positive])}",
        slug: "ai-conv-#{System.unique_integer([:positive])}"
      })

    {:ok, user} =
      tenant
      |> Ecto.build_assoc(:users)
      |> User.changeset(%{
        email: "ai-conv-#{System.unique_integer([:positive])}@test.com",
        password: "password123",
        name: "AI Conv User",
        role: "member"
      })
      |> Repo.insert()

    {tenant, user}
  end

  test "resolve_conversation never creates a row" do
    {tenant, user} = tenant_with_user()

    assert Conversations.resolve_conversation(tenant.id, user.id) == nil
  end

  test "get_or_create_conversation is scoped to tenant and user" do
    {tenant, user} = tenant_with_user()
    {other_tenant, other_user} = tenant_with_user()

    conversation = Conversations.get_or_create_conversation(tenant.id, user.id)
    assert conversation.tenant_id == tenant.id
    assert conversation.user_id == user.id

    other = Conversations.get_or_create_conversation(other_tenant.id, other_user.id)
    refute other.id == conversation.id
  end

  test "messages are tenant scoped and ordered" do
    {tenant, user} = tenant_with_user()
    conversation = Conversations.get_or_create_conversation(tenant.id, user.id)

    {:ok, _} = Conversations.create_message(conversation, %{role: "user", content: "hello"})
    {:ok, _} = Conversations.create_message(conversation, %{role: "assistant", content: "hi"})

    assert Enum.map(Conversations.list_messages(conversation), & &1.content) == ["hello", "hi"]
  end

  test "reset creates a new active conversation and keeps old messages" do
    {tenant, user} = tenant_with_user()
    old = Conversations.get_or_create_conversation(tenant.id, user.id)
    {:ok, _} = Conversations.create_message(old, %{role: "user", content: "keep me"})

    new = Conversations.reset_conversation(tenant.id, user.id)

    refute new.id == old.id
    assert Conversations.list_messages(old) |> Enum.map(& &1.content) == ["keep me"]
    assert Conversations.resolve_conversation(tenant.id, user.id).id == new.id
  end

  test "create_message broadcasts on the user topic" do
    {tenant, user} = tenant_with_user()
    conversation = Conversations.get_or_create_conversation(tenant.id, user.id)

    Phoenix.PubSub.subscribe(Treby.PubSub, Conversations.topic(tenant.id, user.id))
    {:ok, _} = Conversations.create_message(conversation, %{role: "user", content: "ping"})

    user_id = user.id
    assert_receive {:ai_updated, ^user_id}
  end

  test "history is isolated by tenant" do
    {tenant_a, user_a} = tenant_with_user()
    {tenant_b, _user_b} = tenant_with_user()

    conversation = Conversations.get_or_create_conversation(tenant_a.id, user_a.id)
    {:ok, _} = Conversations.create_message(conversation, %{role: "user", content: "acme secret"})

    assert Conversations.resolve_conversation(tenant_b.id, user_a.id) == nil
  end

  test "same session token resumes the conversation" do
    {tenant, user} = tenant_with_user()

    first = Conversations.get_or_create_conversation(tenant.id, user.id, "token-a")
    assert Conversations.resolve_conversation(tenant.id, user.id, "token-a").id == first.id
    assert Conversations.get_or_create_conversation(tenant.id, user.id, "token-a").id == first.id
  end

  test "a new session token starts a fresh conversation" do
    {tenant, user} = tenant_with_user()

    first = Conversations.get_or_create_conversation(tenant.id, user.id, "token-a")
    second = Conversations.get_or_create_conversation(tenant.id, user.id, "token-b")

    refute second.id == first.id
    assert Conversations.resolve_conversation(tenant.id, user.id, "token-a").id == first.id
    assert Conversations.resolve_conversation(tenant.id, user.id, "token-b").id == second.id
  end

  test "reset creates a newer conversation without deleting prior ones" do
    {tenant, user} = tenant_with_user()

    old = Conversations.get_or_create_conversation(tenant.id, user.id, "token-a")
    {:ok, _} = Conversations.create_message(old, %{role: "user", content: "keep me"})

    new = Conversations.reset_conversation(tenant.id, user.id, "token-a")

    refute new.id == old.id
    assert Repo.get(Treby.AI.Conversation, old.id).id == old.id
    assert Conversations.list_messages(old) |> Enum.map(& &1.content) == ["keep me"]
    assert Conversations.resolve_conversation(tenant.id, user.id, "token-a").id == new.id
  end
end
