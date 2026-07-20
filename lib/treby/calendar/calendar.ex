defmodule Treby.Calendar do
  @moduledoc """
  Context for Google Calendar integration.
  Manages calendar connections and provides access to calendar operations.
  """

  import Ecto.Query
  alias Treby.Repo
  alias Treby.Calendar.CalendarConnection

  def get_connection(user_id) do
    CalendarConnection
    |> where([c], c.user_id == ^user_id)
    |> Repo.one()
  end

  def get_connection!(user_id) do
    case get_connection(user_id) do
      nil -> raise Ecto.NoResultsError, queryable: CalendarConnection
      conn -> conn
    end
  end

  def connected?(user_id) do
    CalendarConnection
    |> where([c], c.user_id == ^user_id)
    |> Repo.exists?()
  end

  def connect_google_user(user_id, tenant_id, token_data) do
    attrs = %{
      provider: "google",
      access_token: token_data.access_token,
      refresh_token: token_data.refresh_token,
      token_expires_at: token_data.expires_at,
      google_email: token_data.email,
      calendar_id: "primary",
      connected_at: DateTime.utc_now(),
      user_id: user_id,
      tenant_id: tenant_id
    }

    case get_connection(user_id) do
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

  def disconnect_google_user(user_id) do
    CalendarConnection
    |> where([c], c.user_id == ^user_id)
    |> Repo.delete_all()
  end

  def get_free_busy(user_id, time_min, time_max) do
    case get_connection(user_id) do
      nil -> {:error, :not_connected}
      conn -> Treby.Calendar.Google.free_busy(conn, time_min, time_max)
    end
  end

  def create_event_with_meet(user_id, event_params, attendee_emails \\ []) do
    case get_connection(user_id) do
      nil -> {:error, :not_connected}
      conn -> Treby.Calendar.Google.create_event_with_meet(conn, event_params, attendee_emails)
    end
  end

  def delete_event(user_id, event_id) do
    case get_connection(user_id) do
      nil -> {:error, :not_connected}
      conn -> Treby.Calendar.Google.delete_event(conn, event_id)
    end
  end

  def list_connected_users(tenant_id) do
    CalendarConnection
    |> where([c], c.tenant_id == ^tenant_id)
    |> Repo.all()
  end
end
