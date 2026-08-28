defmodule Treby.CandidatePortal do
  @moduledoc """
  The CandidatePortal context — manages OTP authentication,
  conversations, messages, and candidate notification preferences.
  """

  import Ecto.Query, warn: false
  alias Treby.Repo
  alias Treby.CandidatePortal.{Conversation, Message, CandidateOtp}
  alias Treby.Candidates.Candidate
  alias Treby.Notifications.Email, as: NotificationEmail

  @messages_query from(m in Message, order_by: [asc: m.inserted_at])

  @otp_validity_minutes Application.compile_env(
                          :treby,
                          [Treby.CandidatePortal, :otp_validity_minutes],
                          10
                        )
  @otp_resend_cooldown_seconds Application.compile_env(
                                 :treby,
                                 [Treby.CandidatePortal, :otp_resend_cooldown_seconds],
                                 60
                               )

  @doc """
  Returns the lifetime of a candidate session, in hours.
  """
  def session_lifetime_hours do
    Application.get_env(:treby, Treby.CandidatePortal, [])
    |> Keyword.get(:session_lifetime_hours, 4)
  end

  # --- OTP Login ---

  @doc """
  Generates a one-time password for a candidate and returns the raw 6-digit code.
  Only the SHA-256 hash of the code is stored in `candidate_otps`.

  Invalidates any previously pending code for the candidate. Returns
  `{:error, :rate_limited}` if the candidate requested a code less than
  `otp_resend_cooldown_seconds` ago.
  """
  def generate_otp(%Candidate{} = candidate) do
    now = DateTime.utc_now()

    case latest_pending_otp(candidate.id) do
      %{inserted_at: inserted_at} ->
        if DateTime.diff(now, inserted_at, :second) < @otp_resend_cooldown_seconds do
          {:error, :rate_limited}
        else
          do_generate_otp(candidate, now)
        end

      nil ->
        do_generate_otp(candidate, now)
    end
  end

  defp do_generate_otp(%Candidate{} = candidate, now) do
    raw_code = (:rand.uniform(1_000_000) - 1) |> Integer.to_string() |> String.pad_leading(6, "0")
    hashed_code = hash_otp(raw_code)

    expires_at = now |> DateTime.add(@otp_validity_minutes, :minute)

    Repo.transaction(fn ->
      invalidate_pending_otps(candidate.id)

      %CandidateOtp{}
      |> CandidateOtp.changeset(%{
        code: hashed_code,
        expires_at: expires_at,
        candidate_id: candidate.id,
        tenant_id: candidate.tenant_id
      })
      |> Repo.insert()
    end)
    |> case do
      {:ok, {:ok, _}} -> {:ok, raw_code}
      {:ok, {:error, changeset}} -> {:error, changeset}
      {:error, _} -> {:error, :invalid}
    end
  end

  @doc """
  Verifies a one-time password for a candidate. Returns `{:ok, candidate, tenant}`
  on success and invalidates all pending codes for the candidate.
  """
  def verify_otp(%Candidate{} = candidate, raw_code) do
    now = DateTime.utc_now()
    hashed_code = hash_otp(raw_code)

    CandidateOtp
    |> where([o], o.candidate_id == ^candidate.id and o.code == ^hashed_code)
    |> Repo.one()
    |> case do
      nil ->
        {:error, :invalid_or_expired}

      %{used_at: used_at} when not is_nil(used_at) ->
        {:error, :invalid_or_expired}

      %{attempts: attempts} when attempts >= 5 ->
        {:error, :too_many_attempts}

      otp ->
        if DateTime.compare(otp.expires_at, now) == :lt do
          {:error, :invalid_or_expired}
        else
          Repo.transaction(fn ->
            otp
            |> CandidateOtp.changeset(%{used_at: now})
            |> Repo.update!()

            invalidate_pending_otps(candidate.id)

            candidate
            |> Repo.preload(:tenant)
          end)
          |> case do
            {:ok, candidate} ->
              {:ok, candidate, candidate.tenant}

            {:error, _} ->
              {:error, :invalid}
          end
        end
    end
  end

  @doc """
  Registers a failed verification attempt for a candidate's pending code.
  """
  def record_failed_otp_attempt(%Candidate{} = candidate, raw_code) do
    hashed_code = hash_otp(raw_code)

    CandidateOtp
    |> where([o], o.candidate_id == ^candidate.id and o.code == ^hashed_code)
    |> Repo.one()
    |> case do
      nil ->
        :ok

      otp ->
        otp
        |> CandidateOtp.changeset(%{attempts: otp.attempts + 1})
        |> Repo.update()
        |> case do
          {:ok, _} -> :ok
          {:error, _} -> :ok
        end
    end
  end

  defp latest_pending_otp(candidate_id) do
    CandidateOtp
    |> where([o], o.candidate_id == ^candidate_id and is_nil(o.used_at))
    |> order_by([o], desc: o.inserted_at)
    |> limit(1)
    |> Repo.one()
  end

  defp invalidate_pending_otps(candidate_id) do
    CandidateOtp
    |> where([o], o.candidate_id == ^candidate_id and is_nil(o.used_at))
    |> Repo.update_all(set: [used_at: DateTime.utc_now()])
  end

  defp hash_otp(raw_code) do
    :crypto.hash(:sha256, raw_code) |> Base.url_encode64(padding: false)
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

  @doc """
  Sends an optional notification ping email when a recruiter sends a message,
  respecting the candidate's preferences.
  """
  def notify_new_message(%Candidate{} = candidate, tenant, notification_type, assigns \\ %{}) do
    if notification_enabled?(candidate, notification_type) do
      conversation_id = assigns[:conversation_id]

      NotificationEmail.notification_ping(
        candidate,
        tenant,
        conversation_id,
        notification_type,
        assigns
      )
      |> Treby.Mailer.deliver()
    end

    :ok
  end

  # --- Internal ---

  defp create_message(attrs) do
    %Message{}
    |> Message.changeset(attrs)
    |> Repo.insert()
  end
end
