defmodule Treby.AI.Session do
  @moduledoc """
  Per-user agent session: tracks the current domain and rebuilds history.

  The heavy LLM loop runs in the caller's process (a Task); this GenServer
  only holds lightweight per-user routing state. Conversation history is
  durable in `Treby.AI.Conversations`, so reconnecting rebuilds it intact.
  """

  use GenServer

  require Logger

  alias Treby.AI.{Agent, Conversations, Profiles, Router}

  @name __MODULE__

  def start_link(_opts), do: GenServer.start_link(__MODULE__, :ok, name: @name)

  def ensure(_tenant_id, _user_id), do: :ok

  def domain(tenant_id, user_id), do: GenServer.call(@name, {:domain, tenant_id, user_id})

  def set_domain(tenant_id, user_id, domain),
    do: GenServer.call(@name, {:set_domain, tenant_id, user_id, domain})

  @doc "Entry point used by the chat widget."
  def chat(ctx, text, opts \\ []) do
    tenant_id = ctx.tenant_id
    user_id = ctx.user && ctx.user.id
    last = domain(tenant_id, user_id)
    history = recent_texts(tenant_id, user_id, ctx.session_token)
    classify = Keyword.get(opts, :classify, &Router.classify/3)
    agent_chat = Keyword.get(opts, :agent_chat, &Agent.chat/3)

    verdict = classify.(history, text, last)
    Agent.debug_log("classify", %{verdict: verdict, user_id: user_id})

    if refusal?(verdict) do
      refuse(ctx, verdict)
    else
      result = agent_chat.(ctx, text, Profiles.get(verdict))
      set_domain(tenant_id, user_id, verdict)
      result
    end
  end

  defp refusal?(verdict), do: verdict in [:out_of_domain, :malicious]

  defp refuse(ctx, :malicious) do
    Logger.warning("AI chat refused malicious request for user #{ctx.user && ctx.user.id}")
    persist_refusal(ctx, blocked_reply())
    {:ok, :refused}
  end

  defp refuse(ctx, :out_of_domain) do
    persist_refusal(ctx, off_topic_reply())
    {:ok, :refused}
  end

  defp persist_refusal(ctx, text) do
    conversation =
      Conversations.get_or_create_conversation(
        ctx.tenant_id,
        ctx.user && ctx.user.id,
        ctx.session_token
      )

    Conversations.create_message(conversation, %{role: "assistant", content: text})
    :ok
  end

  defp off_topic_reply do
    "I can only help with your hiring workspace — jobs, candidates, pipeline, analytics, communications, and settings. Ask me something about those."
  end

  defp blocked_reply do
    "I can't respond to that request."
  end

  defp recent_texts(tenant_id, user_id, session_token) do
    conversation = Conversations.get_or_create_conversation(tenant_id, user_id, session_token)

    conversation
    |> Conversations.list_messages()
    |> Enum.take(-8)
    |> Enum.map(fn m -> {m.role, m.content || ""} end)
  end

  @impl true
  def init(:ok), do: {:ok, %{}}

  @impl true
  def handle_call({:domain, t, u}, _from, state),
    do: {:reply, Map.get(state, {t, u}, :recruiter), state}

  @impl true
  def handle_call({:set_domain, t, u, d}, _from, state),
    do: {:reply, :ok, Map.put(state, {t, u}, d)}
end
