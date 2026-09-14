defmodule Treby.Test.RateLimitDenyBackend do
  @moduledoc false
  def check_rate(_id, _scale_ms, _limit), do: {:deny, 42}
end

defmodule TrebyWeb.AiChatWidgetTest do
  use TrebyWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias Treby.AI.{Agent, Conversations}
  alias Treby.{Repo, Tenants}
  alias Treby.Test.AiSSE.Server, as: AiSSEServer
  alias Treby.Accounts.User

  defp setup_tenant_with_user do
    {:ok, tenant} =
      Tenants.create_tenant(%{
        name: "AI Widget #{System.unique_integer([:positive])}",
        slug: "ai-widget-#{System.unique_integer([:positive])}"
      })

    {:ok, user} =
      tenant
      |> Ecto.build_assoc(:users)
      |> User.changeset(%{
        email: "ai-widget-#{System.unique_integer([:positive])}@test.com",
        password: "password123",
        name: "AI Widget User",
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
      "ai_session_token" => "tok-widget"
    })
  end

  test "renders the floating widget on an app page", %{conn: conn} do
    {_tenant, user} = setup_tenant_with_user()

    {:ok, view, _html} = conn |> login(user) |> live(~p"/app")

    assert has_element?(view, "#ai-chat-trigger")
    assert has_element?(view, "#ai-chat-panel")
  end

  test "does not render on public pages", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/")

    refute has_element?(view, "#ai-chat-trigger")
  end

  test "keeps the conversation across page navigation", %{conn: conn} do
    {tenant, user} = setup_tenant_with_user()

    conversation = Conversations.get_or_create_conversation(tenant.id, user.id, "tok-widget")

    {:ok, _} =
      Conversations.create_message(conversation, %{
        role: "assistant",
        content: "persisted across pages"
      })

    {:ok, view, _html} = conn |> login(user) |> live(~p"/app")
    assert render(view) =~ "persisted across pages"

    {:ok, jobs_view, _html} = conn |> login(user) |> live(~p"/#{tenant.slug}/app/jobs")
    assert render(jobs_view) =~ "persisted across pages"
  end

  test "shows a localized error and starts no chat when rate limited", %{conn: conn} do
    {tenant, user} = setup_tenant_with_user()

    previous = Application.get_env(:treby, :rate_limit_backend, Hammer)
    Application.put_env(:treby, :rate_limit_backend, Treby.Test.RateLimitDenyBackend)
    on_exit(fn -> Application.put_env(:treby, :rate_limit_backend, previous) end)

    {:ok, view, _html} = conn |> login(user) |> live(~p"/app")

    Phoenix.LiveView.send_update(view.pid, TrebyWeb.AiChatWidget, id: "ai-chat", open: true)
    view |> form("#ai-form-ai-chat-floating") |> render_submit(%{"message" => "hi"})

    assert render(view) =~ "Too many messages. Please wait a moment and retry."
    refute Conversations.resolve_conversation(tenant.id, user.id, "tok-widget")
  end

  test "reply renders exactly once on the assistant page", %{conn: conn} do
    {tenant, user} = setup_tenant_with_user()

    {server_pid, port} = AiSSEServer.start()
    on_exit(fn -> Process.exit(server_pid, :shutdown) end)

    previous_ai = Application.get_env(:treby, :ai, [])

    Application.put_env(
      :treby,
      :ai,
      previous_ai
      |> Keyword.merge(base_url: "http://127.0.0.1:#{port}/v1", api_key: "test", model: "m")
    )

    on_exit(fn -> Application.put_env(:treby, :ai, previous_ai) end)

    {:ok, view, _html} = conn |> login(user) |> live(~p"/app/ai")

    ctx = %{
      tenant_id: tenant.id,
      user_id: user.id,
      session_token: "tok-widget",
      system_prompt: "You are a terse test assistant."
    }

    assert {:ok, :complete} = Agent.chat(ctx, "ciao")

    # The streamed tail must not re-open a stale streaming bubble over the
    # persisted reply, so the assistant text appears exactly once.
    assert render(view) |> String.split("Ciao mondo") |> length() |> Kernel.-(1) == 1
  end

  test "renders streamed chunks relayed from the page", %{conn: conn} do
    {_tenant, user} = setup_tenant_with_user()

    {:ok, view, _html} = conn |> login(user) |> live(~p"/app")

    send(view.pid, {:ai_stream, user.id, "streaming "})
    send(view.pid, {:ai_stream, user.id, "reply"})

    _ = render(view)
    assert render(view) =~ "streaming reply"
  end

  test "ignores streamed chunks for another user", %{conn: conn} do
    {_tenant, user} = setup_tenant_with_user()

    {:ok, view, _html} = conn |> login(user) |> live(~p"/app")

    send(view.pid, {:ai_stream, "someone-else", "top-secret"})

    refute render(view) =~ "top-secret"
  end

  test "shows assistant errors relayed from the page", %{conn: conn} do
    {_tenant, user} = setup_tenant_with_user()

    {:ok, view, _html} = conn |> login(user) |> live(~p"/app")

    send(view.pid, {:ai_error, user.id, "boom"})

    _ = render(view)
    assert render(view) =~ "boom"
  end

  test "reset starts a newer conversation for the widget session", %{conn: conn} do
    {tenant, user} = setup_tenant_with_user()

    first = Conversations.get_or_create_conversation(tenant.id, user.id, "tok-widget")

    {:ok, view, _html} = conn |> login(user) |> live(~p"/app")

    view |> element("#ai-reset-ai-chat-floating") |> render_click()

    second = Conversations.resolve_conversation(tenant.id, user.id, "tok-widget")
    assert second.id != first.id
    assert render(view) =~ "Assistant"
  end

  test "keeps the chat panel open after a reload", %{conn: conn} do
    {_tenant, user} = setup_tenant_with_user()

    {:ok, view, _html} = conn |> login(user) |> live(~p"/app")

    Phoenix.LiveView.send_update(view.pid, TrebyWeb.AiChatWidget, id: "ai-chat", open: true)
    _ = render(view)

    refute has_element?(view, "#ai-chat-panel.hidden")

    send(view.pid, {:ai_updated, user.id})
    send(view.pid, {:ai_stream, user.id, "hello "})
    send(view.pid, {:ai_stream, user.id, "world"})
    _ = render(view)

    refute has_element?(view, "#ai-chat-panel.hidden")
    assert render(view) =~ "hello world"
  end

  test "keeps thinking indicator while the last message is from the user", %{conn: conn} do
    {tenant, user} = setup_tenant_with_user()

    conversation = Conversations.get_or_create_conversation(tenant.id, user.id, "tok-widget")

    {:ok, _} =
      Conversations.create_message(conversation, %{role: "user", content: "hello"})

    {:ok, view, _html} = conn |> login(user) |> live(~p"/app")

    Phoenix.LiveView.send_update(view.pid, TrebyWeb.AiChatWidget, id: "ai-chat", thinking: true)
    _ = render(view)

    assert has_element?(view, "#ai-thinking-ai-chat-floating")
    assert has_element?(view, "#ai-input-ai-chat-floating[disabled]")

    send(view.pid, {:ai_updated, user.id})
    _ = render(view)

    assert has_element?(view, "#ai-thinking-ai-chat-floating")
    assert has_element?(view, "#ai-input-ai-chat-floating[disabled]")
  end

  test "clears the thinking indicator once the assistant answers", %{conn: conn} do
    {tenant, user} = setup_tenant_with_user()

    conversation = Conversations.get_or_create_conversation(tenant.id, user.id, "tok-widget")

    {:ok, _} =
      Conversations.create_message(conversation, %{role: "user", content: "hello"})

    {:ok, view, _html} = conn |> login(user) |> live(~p"/app")

    Phoenix.LiveView.send_update(view.pid, TrebyWeb.AiChatWidget, id: "ai-chat", thinking: true)
    _ = render(view)

    {:ok, _} =
      Conversations.create_message(conversation, %{role: "assistant", content: "hi there"})

    send(view.pid, {:ai_updated, user.id})
    _ = render(view)

    refute has_element?(view, "#ai-thinking-ai-chat-floating")
    refute has_element?(view, "#ai-input-ai-chat-floating[disabled]")
    assert render(view) =~ "hi there"
  end
end
