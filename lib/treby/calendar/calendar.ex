defmodule Treby.Calendar do
  @moduledoc """
  Facade for calendar and meeting providers.

  Manages provider connections, resolves meetings, and dispatches provider
  operations. Availability aggregation lives in `Treby.Availability`; the
  internal (always-active) calendar provider is `Treby.Calendar.Providers.Treby`.
  """

  import Ecto.Query
  alias Treby.Repo
  alias Treby.Calendar.CalendarConnection

  @provider_modules %{"google" => Treby.Calendar.Google}

  @doc "Returns the provider module for a provider name."
  def provider_module(provider) do
    Map.fetch!(@provider_modules, provider)
  end

  @doc "Returns all calendar connections for a user."
  def list_connections_for_user(user_id) do
    CalendarConnection
    |> where([c], c.user_id == ^user_id)
    |> order_by([c], asc: c.connected_at)
    |> Repo.all()
  end

  @doc "Returns the connection for a user and provider, if any."
  def get_connection(user_id, provider) do
    CalendarConnection
    |> where([c], c.user_id == ^user_id and c.provider == ^provider)
    |> Repo.one()
  end

  @doc """
  Returns the first connection for a user (backward compatibility).

  Prefer `get_connection/2` now that multiple providers per user are supported.
  """
  def get_connection(user_id) do
    CalendarConnection
    |> where([c], c.user_id == ^user_id)
    |> order_by([c], asc: c.connected_at)
    |> Repo.one()
  end

  @doc "Returns true when the user has a connection for the given provider."
  def connected?(user_id, provider \\ "google") do
    CalendarConnection
    |> where([c], c.user_id == ^user_id and c.provider == ^provider)
    |> Repo.exists?()
  end

  @doc "Connects the user's Google Calendar account with the given token data."
  def connect_google_user(user_id, tenant_id, token_data) do
    connect_provider("google", user_id, tenant_id, token_data)
  end

  @doc "Connects (or reconnects) a provider connection for a user."
  def connect_provider(provider, user_id, tenant_id, token_data) do
    attrs = %{
      provider: provider,
      access_token: token_data.access_token,
      refresh_token: token_data.refresh_token,
      token_expires_at: token_data.expires_at,
      provider_email: token_data.email,
      calendar_id: "primary",
      connected_at: DateTime.utc_now(),
      user_id: user_id,
      tenant_id: tenant_id
    }

    case get_connection(user_id, provider) do
      nil ->
        %CalendarConnection{}
        |> CalendarConnection.changeset(attrs)
        |> Repo.insert()

      existing ->
        existing
        |> CalendarConnection.changeset(attrs)
        |> Repo.update()
    end
  end

  @doc "Disconnects the user's Google Calendar account."
  def disconnect_google_user(user_id), do: disconnect_provider(user_id, "google")

  @doc "Disconnects a provider connection for a user."
  def disconnect_provider(user_id, provider) do
    CalendarConnection
    |> where([c], c.user_id == ^user_id and c.provider == ^provider)
    |> Repo.delete_all()
  end

  @doc "Returns all calendar connections for a tenant."
  def list_connected_users(tenant_id) do
    CalendarConnection
    |> where([c], c.tenant_id == ^tenant_id)
    |> Repo.all()
  end

  @doc """
  Resolves the meeting provider for an interview with the given examiners.

  Returns `{:calendar_event, owner_id, :google_meet}` when a required examiner
  is Google-connected (the first connected examiner owns the event), or
  `{:meeting_url, :jitsi}` otherwise.
  """
  def resolve_meeting(examiner_ids) do
    case Enum.find(examiner_ids, &connected?(&1, "google")) do
      nil -> {:meeting_url, :jitsi}
      owner_id -> {:calendar_event, owner_id, :google_meet}
    end
  end

  @doc "Fetches busy periods from a provider for a user over a time range."
  def get_free_busy(user_id, provider, time_min, time_max) do
    case get_connection(user_id, provider) do
      nil -> {:error, :not_connected}
      conn -> provider_module(provider).fetch_busy(conn, time_min, time_max)
    end
  end

  @doc "Dispatches a busy fetch to a connection's provider module."
  def fetch_provider_busy(%CalendarConnection{} = conn, time_min, time_max) do
    provider_module(conn.provider).fetch_busy(conn, time_min, time_max)
  end

  @doc "Creates an event with a video conference link on the user's provider calendar."
  def create_event_with_meet(user_id, provider, event_params, attendee_emails \\ []) do
    case get_connection(user_id, provider) do
      nil -> {:error, :not_connected}
      conn -> provider_module(provider).create_event(conn, event_params, attendee_emails)
    end
  end

  @doc "Deletes an event from the user's provider calendar."
  def delete_event(user_id, provider, provider_event_id) do
    case get_connection(user_id, provider) do
      nil -> {:error, :not_connected}
      conn -> provider_module(provider).delete_event(conn, provider_event_id)
    end
  end
end
