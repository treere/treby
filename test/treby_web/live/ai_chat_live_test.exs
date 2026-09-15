defmodule TrebyWeb.AiChatLiveTest do
  use TrebyWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias Treby.AI.Conversations
  alias Treby.{Repo, Tenants}
  alias Treby.Accounts.User
  alias Treby.Jobs.Job

  defp setup_tenant_with_user do
    {:ok, tenant} =
      Tenants.create_tenant(%{
        name: "AI Live #{System.unique_integer([:positive])}",
        slug: "ai-live-#{System.unique_integer([:positive])}"
      })

    {:ok, user} =
      tenant
      |> Ecto.build_assoc(:users)
      |> User.changeset(%{
        email: "ai-live-#{System.unique_integer([:positive])}@test.com",
        password: "password123",
        name: "AI Live User",
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

  defp login(conn, user) do
    init_test_session(conn, %{
      "user_id" => user.id,
      "tenant_id" => user.tenant_id,
      "ai_session_token" => "tok-live"
    })
  end

  test "redirects unauthenticated visitors", %{conn: conn} do
    {tenant, _user} = setup_tenant_with_user()

    assert {:error, {:redirect, _}} = live(conn, ~p"/#{tenant.slug}/app/ai")
  end

  test "renders the chat page for a member", %{conn: conn} do
    {tenant, user} = setup_tenant_with_user()

    {:ok, view, _html} = conn |> login(user) |> live(~p"/#{tenant.slug}/app/ai")

    assert has_element?(view, "#ai-form-ai-chat")
    assert has_element?(view, "#ai-input-ai-chat")
  end

  test "history is isolated by tenant", %{conn: conn} do
    {tenant_a, user_a} = setup_tenant_with_user()
    {tenant_b, user_b} = setup_tenant_with_user()

    conversation_b = Conversations.get_or_create_conversation(tenant_b.id, user_b.id)

    {:ok, _} =
      Conversations.create_message(conversation_b, %{role: "assistant", content: "beta secret"})

    {:ok, view, _html} = conn |> login(user_a) |> live(~p"/#{tenant_a.slug}/app/ai")

    refute render(view) =~ "beta secret"
  end

  test "confirming a pending destructive run executes it", %{conn: conn} do
    {tenant, user} = setup_tenant_with_user()

    job =
      tenant
      |> Ecto.build_assoc(:jobs)
      |> Job.changeset(%{title: "Delete me", description: "d"})
      |> Repo.insert!()

    conversation = Conversations.get_or_create_conversation(tenant.id, user.id, "tok-live")

    {:ok, message} =
      Conversations.create_message(conversation, %{role: "assistant", content: "Confirm?"})

    {:ok, run} =
      Conversations.create_tool_run(message, %{
        tool: "delete_job",
        args: %{"job_id" => job.id},
        status: "pending_confirm"
      })

    {:ok, view, _html} = conn |> login(user) |> live(~p"/#{tenant.slug}/app/ai")

    assert has_element?(view, "#confirm-#{run.id}")
    view |> element("#confirm-#{run.id}") |> render_click()

    assert Repo.get(Job, job.id) == nil
  end
end
