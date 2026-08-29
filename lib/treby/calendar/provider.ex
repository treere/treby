defmodule Treby.Calendar.Provider do
  @moduledoc """
  Behaviour for calendar providers: presence (busy periods) and event lifecycle.

  Implementations handle a specific external calendar (e.g. Google Calendar).
  The internal Treby calendar is `Treby.Calendar.Providers.Treby`.
  """

  @type busy_period :: %{start: DateTime.t(), end: DateTime.t()}

  @doc "Returns the busy periods for a connection over a time range."
  @callback fetch_busy(connection :: term(), time_min :: DateTime.t(), time_max :: DateTime.t()) ::
              {:ok, [busy_period()]} | {:error, term()}

  @doc "Creates an event on the connection's calendar, returning its provider id and optional video link."
  @callback create_event(
              connection :: term(),
              event_params :: map(),
              attendee_emails :: [String.t()]
            ) ::
              {:ok, %{provider_event_id: String.t(), video_link: String.t() | nil}}
              | {:error, term()}

  @doc "Deletes an event on the connection's calendar."
  @callback delete_event(connection :: term(), provider_event_id :: String.t()) ::
              :ok | {:error, term()}
end
