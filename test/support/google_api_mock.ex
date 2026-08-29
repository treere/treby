defmodule Treby.GoogleApiMock do
  @moduledoc """
  Test helpers for stubbing Google OAuth/Calendar HTTP endpoints via `Req.Test`.

  Requests made during tests are routed to this stub through the global Req default
  options configured in `config/test.exs`:

      config :req, default_options: [plug: {Req.Test, Treby.GoogleApiMock}]

  Register a stub per test with the functions in this module. Stubs are owned by the
  calling process, so only requests made from that process are intercepted. If a test
  needs to stub requests from another process, use `Req.Test.allow/3` with that pid.
  """

  alias Plug.Conn
  import ExUnit.Assertions
  import Req.Test

  @token_path "/token"

  @doc """
  Stubs the OAuth token endpoint (`POST https://oauth2.googleapis.com/token`) to return
  a successful response with the given `access_token`.
  """
  def stub_token_refresh(access_token, expires_in \\ 3600) do
    stub_endpoint(@token_path, %{"access_token" => access_token, "expires_in" => expires_in})
  end

  @doc """
  Stubs the OAuth token endpoint to return an error response with the given `status`
  and JSON `body`.
  """
  def stub_token_error(status, body) do
    stub_endpoint(@token_path, body, status: status)
  end

  defp stub_endpoint(path, body, opts \\ []) do
    Req.Test.stub(Treby.GoogleApiMock, fn conn ->
      assert conn.request_path == path

      conn
      |> Conn.put_status(Keyword.get(opts, :status, 200))
      |> json(body)
    end)
  end
end
