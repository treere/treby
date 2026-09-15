defmodule Treby.AI.Conversations do
  @moduledoc """
  Persistence for AI chat, scoped by `(tenant_id, user_id, session_token)`.

  The current conversation is the most recent row for the login session token.
  Mount never creates a row; only the first message (`get_or_create_conversation/3`)
  or `reset_conversation/3` starts a new one. Rows are never deleted or
  status-mutated.
  """

  import Ecto.Query, warn: false

  alias Treby.AI.{Conversation, Message, ToolRun}
  alias Treby.Repo

  @doc "PubSub topic for one user's chat inside one tenant."
  def topic(tenant_id, user_id), do: "ai:#{tenant_id}:#{user_id}"

  @doc """
  Resolve the conversation for a session token without ever creating one.

  Returns the most recent conversation for `(tenant_id, user_id, session_token)`,
  otherwise nil.
  """
  def resolve_conversation(tenant_id, user_id, session_token \\ nil) do
    Conversation
    |> where([c], c.tenant_id == ^tenant_id and c.user_id == ^user_id)
    |> filter_session_token(session_token)
    |> order_by([c], desc: c.inserted_at, desc: c.id)
    |> limit(1)
    |> Repo.one()
  end

  defp filter_session_token(query, nil), do: where(query, [c], is_nil(c.session_token))
  defp filter_session_token(query, token), do: where(query, [c], c.session_token == ^token)

  @doc "Resolve the session conversation or create one lazily."
  def get_or_create_conversation(tenant_id, user_id, session_token \\ nil) do
    case resolve_conversation(tenant_id, user_id, session_token) do
      nil -> create_conversation(tenant_id, user_id, session_token)
      conversation -> conversation
    end
  end

  defp create_conversation(tenant_id, user_id, session_token) do
    {:ok, conversation} =
      %Conversation{}
      |> Conversation.changeset(%{
        tenant_id: tenant_id,
        user_id: user_id,
        session_token: session_token
      })
      |> Repo.insert()

    broadcast(conversation)
    conversation
  end

  @doc """
  Start a newer conversation within the same session.

  Prior conversations are left intact — nothing is deleted or status-mutated.
  """
  def reset_conversation(tenant_id, user_id, session_token \\ nil) do
    create_conversation(tenant_id, user_id, session_token)
  end

  @doc "List a conversation's messages oldest first."
  def list_messages(%Conversation{id: id, tenant_id: tenant_id}) do
    Message
    |> where([m], m.conversation_id == ^id and m.tenant_id == ^tenant_id)
    |> order_by([m], asc: m.inserted_at, asc: m.id)
    |> Repo.all()
  end

  def list_messages(nil), do: []

  @doc "Persist a message and broadcast the update."
  def create_message(%Conversation{} = conversation, attrs) do
    attrs =
      attrs
      |> Map.new()
      |> Map.put(:conversation_id, conversation.id)
      |> Map.put(:tenant_id, conversation.tenant_id)

    case %Message{} |> Message.changeset(attrs) |> Repo.insert() do
      {:ok, message} ->
        broadcast(conversation)
        {:ok, message}

      error ->
        error
    end
  end

  @doc "Persist a pending tool run belonging to a message."
  def create_tool_run(%Message{} = message, attrs) do
    attrs =
      attrs
      |> Map.new()
      |> Map.put(:message_id, message.id)
      |> Map.put(:tenant_id, message.tenant_id)

    %ToolRun{} |> ToolRun.changeset(attrs) |> Repo.insert()
  end

  @doc "Update a tool run's status/result and broadcast the update."
  def update_tool_run(%ToolRun{} = run, attrs) do
    case run |> ToolRun.changeset(attrs) |> Repo.update() do
      {:ok, updated} ->
        broadcast_for_tenant(updated.tenant_id, updated.message_id)
        {:ok, updated}

      error ->
        error
    end
  end

  def get_tool_run(tenant_id, id) do
    ToolRun
    |> where([r], r.id == ^id and r.tenant_id == ^tenant_id)
    |> Repo.one()
  end

  @doc "Pending tool runs for a conversation, oldest first."
  def list_pending_tool_runs(%Conversation{} = conversation) do
    ToolRun
    |> join(:inner, [r], m in Message, on: m.id == r.message_id)
    |> where(
      [r, m],
      r.status == "pending_confirm" and m.conversation_id == ^conversation.id and
        r.tenant_id == ^conversation.tenant_id
    )
    |> order_by([r], asc: r.inserted_at, asc: r.id)
    |> Repo.all()
  end

  def list_pending_tool_runs(nil), do: []

  @doc """
  First user prompt that led to a tool run, truncated for audit metadata.
  """
  def prompt_excerpt(%ToolRun{message_id: message_id, tenant_id: tenant_id}) do
    case Repo.get(Message, message_id) do
      nil ->
        nil

      %Message{conversation_id: conversation_id, inserted_at: at} ->
        Message
        |> where([m], m.conversation_id == ^conversation_id and m.tenant_id == ^tenant_id)
        |> where([m], m.role == "user" and m.inserted_at <= ^at)
        |> order_by([m], desc: m.inserted_at, desc: m.id)
        |> limit(1)
        |> Repo.one()
        |> case do
          nil -> nil
          message -> String.slice(message.content || "", 0, 200)
        end
    end
  end

  @doc "Broadcast a conversation update to its owner."
  def broadcast(%Conversation{tenant_id: tenant_id, user_id: user_id}) do
    Phoenix.PubSub.broadcast(Treby.PubSub, topic(tenant_id, user_id), {:ai_updated, user_id})
  end

  defp broadcast_for_tenant(tenant_id, message_id) do
    query =
      from m in Message,
        where: m.id == ^message_id and m.tenant_id == ^tenant_id,
        join: c in assoc(m, :conversation),
        select: c.user_id

    case Repo.one(query) do
      nil ->
        :ok

      user_id ->
        Phoenix.PubSub.broadcast(Treby.PubSub, topic(tenant_id, user_id), {:ai_updated, user_id})
    end
  end
end
