defmodule Treby.Calendar.Google do
  @moduledoc """
  Google Calendar provider implementing `Treby.Calendar.Provider`.

  Handles token management, FreeBusy queries, event creation with Google Meet,
  and event deletion.
  """

  @behaviour Treby.Calendar.Provider

  @base_url "https://www.googleapis.com/calendar/v3"
  @token_url "https://oauth2.googleapis.com/token"

  alias Treby.Calendar.CalendarConnection

  @impl true
  def fetch_busy(%Treby.Calendar.CalendarConnection{} = conn, time_min, time_max) do
    with {:ok, token} <- get_valid_token(conn) do
      body = %{
        timeMin: DateTime.to_iso8601(time_min),
        timeMax: DateTime.to_iso8601(time_max),
        items: [%{id: conn.calendar_id}]
      }

      req =
        Req.new(base_url: @base_url)
        |> Req.Request.put_header("authorization", "Bearer #{token}")

      case Req.post(req, url: "/freeBusy", json: body) do
        {:ok, %{status: 200, body: resp}} ->
          busy_periods =
            resp
            |> get_in(["calendars", conn.calendar_id, "busy"])
            |> Enum.map(fn period ->
              {:ok, start_dt, _} = DateTime.from_iso8601(period["start"])
              {:ok, end_dt, _} = DateTime.from_iso8601(period["end"])

              %{
                start: start_dt,
                end: end_dt
              }
            end)

          {:ok, busy_periods}

        {:ok, %{body: resp}} ->
          {:error, {:api_error, resp}}

        {:error, reason} ->
          {:error, {:network_error, reason}}
      end
    end
  end

  @impl true
  def create_event(
        %Treby.Calendar.CalendarConnection{} = conn,
        event_params,
        attendee_emails \\ []
      ) do
    with {:ok, token} <- get_valid_token(conn) do
      request_id = Ecto.UUID.generate()

      body =
        %{
          summary: event_params.summary,
          description: event_params.description || "",
          start: %{
            dateTime: DateTime.to_iso8601(event_params.start_at),
            timeZone: event_params.timezone || "UTC"
          },
          end: %{
            dateTime: DateTime.to_iso8601(event_params.end_at),
            timeZone: event_params.timezone || "UTC"
          },
          conferenceData: %{
            createRequest: %{
              requestId: request_id,
              conferenceSolutionKey: %{
                type: "hangoutsMeet"
              }
            }
          }
        }
        |> maybe_add_attendees(attendee_emails)

      req =
        Req.new(base_url: @base_url)
        |> Req.Request.put_header("authorization", "Bearer #{token}")

      params = [conferenceDataVersion: 1, sendUpdates: "none"]

      case Req.post(req, url: "/calendars/primary/events", json: body, params: params) do
        {:ok, %{status: 200, body: resp}} ->
          {:ok,
           %{
             provider_event_id: resp["id"],
             video_link: resp["hangoutLink"],
             html_link: resp["htmlLink"]
           }}

        {:ok, %{body: resp}} ->
          {:error, {:api_error, resp}}

        {:error, reason} ->
          {:error, {:network_error, reason}}
      end
    end
  end

  @impl true
  def delete_event(%Treby.Calendar.CalendarConnection{} = conn, provider_event_id) do
    with {:ok, token} <- get_valid_token(conn) do
      req =
        Req.new(base_url: @base_url)
        |> Req.Request.put_header("authorization", "Bearer #{token}")

      case Req.delete(req,
             url: "/calendars/primary/events/#{provider_event_id}",
             params: [sendUpdates: "none"]
           ) do
        {:ok, %{status: 204}} ->
          :ok

        {:ok, %{status: 404}} ->
          :ok

        {:ok, %{body: resp}} ->
          {:error, {:api_error, resp}}

        {:error, reason} ->
          {:error, {:network_error, reason}}
      end
    end
  end

  def get_valid_token(%CalendarConnection{} = conn) do
    if token_valid?(conn) do
      {:ok, conn.access_token}
    else
      refresh_token(conn)
    end
  end

  defp token_valid?(%{token_expires_at: nil}), do: false
  defp token_valid?(%{access_token: nil}), do: false

  defp token_valid?(%{token_expires_at: expires_at}) do
    DateTime.compare(DateTime.utc_now(), DateTime.add(expires_at, -5, :minute)) == :lt
  end

  defp refresh_token(%{refresh_token: nil}) do
    {:error, :no_refresh_token}
  end

  defp refresh_token(%Treby.Calendar.CalendarConnection{} = conn) do
    client_id = fetch_config!(:google_client_id)
    client_secret = fetch_config!(:google_client_secret)

    body = %{
      client_id: client_id,
      client_secret: client_secret,
      refresh_token: conn.refresh_token,
      grant_type: "refresh_token"
    }

    case Req.post(@token_url, form: body) do
      {:ok, %{status: 200, body: resp}} ->
        new_token = resp["access_token"]
        expires_in = resp["expires_in"]
        expires_at = DateTime.utc_now() |> DateTime.add(expires_in, :second)

        changeset =
          CalendarConnection.changeset(conn, %{
            access_token: new_token,
            token_expires_at: expires_at
          })

        case Treby.Repo.update(changeset) do
          {:ok, updated} -> {:ok, updated.access_token}
          {:error, _} -> {:ok, new_token}
        end

      {:ok, %{body: resp}} ->
        {:error, {:refresh_failed, resp}}

      {:error, reason} ->
        {:error, {:network_error, reason}}
    end
  end

  defp maybe_add_attendees(body, []), do: body

  defp maybe_add_attendees(body, emails) do
    Map.put(body, :attendees, Enum.map(emails, &%{email: &1}))
  end

  defp fetch_config!(key) do
    case Application.get_env(:treby, key) do
      nil -> raise "Missing config: #{key}"
      val -> val
    end
  end
end
