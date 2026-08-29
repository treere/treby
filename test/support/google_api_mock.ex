defmodule Treby.GoogleApiMock do
  @moduledoc """
  Test helpers for stubbing Google OAuth/Calendar HTTP endpoints via `Req.Test`.

  Requests made during tests are routed to this stub through the global Req default
  options configured in `config/test.exs`:

      config :req, default_options: [plug: {Req.Test, Treby.GoogleApiMock}]

  Register one or more endpoint stubs per test with the functions in this module.
  Each call registers a dispatcher plug that handles every previously registered
  route, so multiple endpoints (e.g. token refresh + free/busy) can be stubbed in
  the same test. Stubs are owned by the calling process; if a test needs stubs to
  be reachable from another process (e.g. a LiveView), use `Req.Test.allow/3`.
  """

  alias Plug.Conn
  import Req.Test

  @token_path "/token"
  @free_busy_path "/calendar/v3/freeBusy"
  @events_path "/calendar/v3/calendars/primary/events"
  @routes_key {__MODULE__, :routes}

  @doc """
  Stubs the OAuth token endpoint (`POST https://oauth2.googleapis.com/token`) to return
  a successful response with the given `access_token`.
  """
  def stub_token_refresh(access_token, expires_in \\ 3600) do
    add_route(&match_path?(@token_path, &1), fn conn ->
      json(conn, %{"access_token" => access_token, "expires_in" => expires_in})
    end)
  end

  @doc """
  Stubs the OAuth token endpoint to return an error response with the given `status`
  and JSON `body`.
  """
  def stub_token_error(status, body) do
    add_route(&match_path?(@token_path, &1), fn conn ->
      conn |> Conn.put_status(status) |> json(body)
    end)
  end

  @doc """
  Stubs the Google Calendar FreeBusy endpoint to return the given busy periods.
  """
  def stub_free_busy(busy_periods \\ [], calendar_id \\ "primary") do
    add_route(&match_path?(@free_busy_path, &1), fn conn ->
      json(conn, %{"calendars" => %{calendar_id => %{"busy" => busy_periods}}})
    end)
  end

  @doc """
  Stubs the Google Calendar event creation endpoint to return an event with a
  hangout (Meet) link.
  """
  def stub_event_create(
        event_id \\ "evt-#{System.unique_integer([:positive])}",
        hangout_link \\ "https://meet.google.com/abc-defg-hij"
      ) do
    add_route(&match_path?(@events_path, &1), fn conn ->
      json(conn, %{
        "id" => event_id,
        "hangoutLink" => hangout_link,
        "htmlLink" => "https://calendar.google.com/calendar/event?eid=abc"
      })
    end)
  end

  @doc """
  Stubs the Google Calendar event deletion endpoint to succeed.
  """
  def stub_event_delete do
    add_route(
      fn conn -> String.starts_with?(conn.request_path, @events_path <> "/") end,
      fn conn ->
        Conn.send_resp(conn, 204, "")
      end
    )
  end

  defp add_route(matcher, handler) do
    routes = Process.get(@routes_key, []) ++ [{matcher, handler}]
    Process.put(@routes_key, routes)

    Req.Test.stub(Treby.GoogleApiMock, fn conn -> dispatch(conn, routes) end)
    :ok
  end

  defp dispatch(conn, routes) do
    case Enum.find(routes, fn {matcher, _handler} -> matcher.(conn) end) do
      {_matcher, handler} ->
        handler.(conn)

      nil ->
        raise "no GoogleApiMock stub registered for path #{conn.request_path}"
    end
  end

  defp match_path?(path, conn), do: conn.request_path == path
end
