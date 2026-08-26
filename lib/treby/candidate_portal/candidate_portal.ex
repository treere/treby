defmodule Treby.CandidatePortal do
  @moduledoc """
  The CandidatePortal context — manages magic link authentication,
  conversations, messages, and candidate notification preferences.
  """

  import Ecto.Query, warn: false
  alias Treby.Repo
  alias Treby.CandidatePortal.{CandidateToken, Conversation, Message}
  alias Treby.Candidates.Candidate

  @messages_query from(m in Message, order_by: [asc: m.inserted_at])

  @token_validity_minutes 15

  # --- Magic Link Tokens ---

  @doc """
  Generates a magic link token for a candidate.
  Returns {:ok, raw_token} on success.
  The raw token is included in the email URL; only the hash is stored.
  """
  def generate_magic_link_token(%Candidate{} = candidate) do
    raw_token = :crypto.strong_rand_bytes(32) |> Base.url_encode64(padding: false)
    hashed_token = hash_token(raw_token)

    expires_at = DateTime.utc_now() |> DateTime.add(@token_validity_minutes, :minute)

    %CandidateToken{}
    |> CandidateToken.changeset(%{
      token: hashed_token,
      expires_at: expires_at,
      candidate_id: candidate.id,
      tenant_id: candidate.tenant_id
    })
    |> Repo.insert()
    |> case do
      {:ok, _} -> {:ok, raw_token}
      {:error, changeset} -> {:error, changeset}
    end
  end

  @doc """
  Validates a magic link token. Returns {:ok, candidate, tenant} on success.
  Marks the token as used.
  """
  def validate_magic_link_token(raw_token) do
    hashed_token = hash_token(raw_token)

    now = DateTime.utc_now()

    CandidateToken
    |> where([t], t.token == ^hashed_token)
    |> Repo.one()
    |> case do
      nil ->
        {:error, :invalid_token}

      token ->
        cond do
          not is_nil(token.used_at) ->
            {:error, :token_already_used}

          DateTime.compare(token.expires_at, now) == :lt ->
            {:error, :token_expired}

          true ->
            token
            |> CandidateToken.changeset(%{used_at: DateTime.utc_now()})
            |> Repo.update()

            candidate = Repo.get!(Candidate, token.candidate_id) |> Repo.preload(:tenant)
            {:ok, candidate, candidate.tenant}
        end
    end
  end

  defp hash_token(raw_token) do
    :crypto.hash(:sha256, raw_token) |> Base.url_encode64(padding: false)
  end

  # --- Conversations ---

  @doc """
  Creates a new conversation. Optionally creates an initial system message.
  """
  def create_conversation(attrs, system_message_body \\ nil) do
    now = DateTime.utc_now()

    string_attrs =
      attrs
      |> Enum.into(%{}, fn {k, v} -> {to_string(k), v} end)
      |> Map.put_new("last_message_at", now)

    %Conversation{}
    |> Conversation.changeset(string_attrs)
    |> Repo.insert()
    |> case do
      {:ok, conversation} ->
        if system_message_body do
          create_message(%{
            sender_type: "system",
            body: system_message_body,
            message_type: "status_update",
            conversation_id: conversation.id
          })
        end

        {:ok, conversation}

      error ->
        error
    end
  end

  @doc """
  Sends a message in a conversation. Updates conversation last_message_at and status.
  """
  def send_message(attrs) do
    now = DateTime.utc_now()

    %Message{}
    |> Message.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, message} ->
        # Update conversation last_message_at
        conversation = Repo.get!(Conversation, message.conversation_id)

        status =
          case message.sender_type do
            "recruiter" ->
              if message.message_type in ["request_info"], do: "waiting_candidate", else: "open"

            "candidate" ->
              "open"

            _ ->
              conversation.status
          end

        conversation
        |> Conversation.changeset(%{last_message_at: now, status: status})
        |> Repo.update()

        {:ok, message}

      error ->
        error
    end
  end

  @doc """
  Lists conversations for a candidate in a tenant, with the last message preloaded.
  """
  def list_conversations_for_candidate(candidate_id, tenant_id) do
    Conversation
    |> where([c], c.candidate_id == ^candidate_id and c.tenant_id == ^tenant_id)
    |> order_by([c], desc: c.last_message_at)
    |> Repo.all()
    |> Repo.preload(messages: @messages_query)
  end

  @doc """
  Lists conversations for an application.
  """
  def list_conversations_for_application(application_id, tenant_id) do
    Conversation
    |> where([c], c.application_id == ^application_id and c.tenant_id == ^tenant_id)
    |> order_by([c], desc: c.last_message_at)
    |> Repo.all()
    |> Repo.preload(messages: @messages_query)
  end

  @doc """
  Gets a single conversation with all messages preloaded in chronological order.
  """
  def get_conversation!(id) do
    Conversation
    |> Repo.get!(id)
    |> Repo.preload(messages: @messages_query)
  end

  @doc """
  Closes a conversation.
  """
  def close_conversation(%Conversation{} = conversation) do
    conversation
    |> Conversation.changeset(%{status: "closed"})
    |> Repo.update()
  end

  # --- System Message Helpers ---

  @doc """
  Creates a status update system message (e.g., stage change).
  """
  def create_status_update_message(conversation_id, body, metadata \\ %{}) do
    create_message(%{
      sender_type: "system",
      body: body,
      message_type: "status_update",
      metadata: metadata,
      conversation_id: conversation_id
    })
  end

  @doc """
  Creates a rejection message with structured reason.
  """
  def create_rejection_message(conversation_id, reason, feedback \\ nil) do
    metadata = %{"rejection_reason" => reason}
    metadata = if feedback, do: Map.put(metadata, "feedback", feedback), else: metadata

    create_message(%{
      sender_type: "recruiter",
      body: "This application has been declined.",
      message_type: "rejection",
      metadata: metadata,
      conversation_id: conversation_id
    })
  end

  @doc """
  Creates an info request message.
  """
  def create_info_request_message(conversation_id, request_type, custom_text \\ nil) do
    body = custom_text || "We need some additional information to proceed with your application."

    metadata = %{"request_type" => request_type}

    create_message(%{
      sender_type: "recruiter",
      body: body,
      message_type: "request_info",
      metadata: metadata,
      conversation_id: conversation_id
    })
  end

  # --- Candidate Notification Preferences ---

  @default_notification_preferences %{
    "new_message" => true,
    "status_change" => true,
    "interview_update" => true,
    "important_only" => false
  }

  @doc """
  Returns the notification preferences for a candidate.
  Falls back to defaults for any missing keys.
  """
  def get_notification_preferences(%Candidate{} = candidate) do
    stored = candidate.notification_preferences || %{}
    Map.merge(@default_notification_preferences, stored)
  end

  @doc """
  Sets a single notification preference for a candidate.
  """
  def set_notification_preference(%Candidate{} = candidate, key, value) when is_boolean(value) do
    prefs = get_notification_preferences(candidate) |> Map.put(key, value)

    candidate
    |> Candidate.changeset(%{notification_preferences: prefs})
    |> Repo.update()
  end

  @doc """
  Checks if a notification type is enabled for a candidate.
  Respects the "important_only" flag.
  """
  def notification_enabled?(%Candidate{} = candidate, notification_type) do
    prefs = get_notification_preferences(candidate)

    if prefs["important_only"] and
         notification_type not in ["status_change", "interview_update", "offer", "rejection"] do
      false
    else
      Map.get(prefs, notification_type, true)
    end
  end

  # --- Internal ---

  defp create_message(attrs) do
    %Message{}
    |> Message.changeset(attrs)
    |> Repo.insert()
  end
end
