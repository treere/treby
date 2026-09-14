defmodule Treby.Test.AiSSEPlug do
  @moduledoc false
  @behaviour Plug

  import Plug.Conn

  @events [
    %{"choices" => [%{"delta" => %{"role" => "assistant"}, "index" => 0}]},
    %{"choices" => [%{"delta" => %{"content" => "Ciao"}, "index" => 0}]},
    %{"choices" => [%{"delta" => %{"content" => " mondo"}, "index" => 0}]},
    %{"choices" => [%{"delta" => %{}, "index" => 0, "finish_reason" => "stop"}]}
  ]

  @impl Plug
  def init(opts), do: opts

  @impl Plug
  def call(conn, _opts) do
    conn
    |> put_resp_content_type("text/event-stream")
    |> send_chunked(200)
    |> stream_events()
  end

  defp stream_events(conn) do
    conn =
      Enum.reduce(@events, conn, fn event, conn ->
        Process.sleep(45)
        {:ok, conn} = chunk(conn, "data: #{Jason.encode!(event)}\n\n")
        conn
      end)

    {:ok, conn} = chunk(conn, "data: [DONE]\n\n")
    conn
  end
end

defmodule Treby.Test.AiSSE.Server do
  @moduledoc false

  def start do
    {:ok, socket} = :gen_tcp.listen(0, [:binary, ip: {127, 0, 0, 1}, active: false])
    {:ok, port} = :inet.port(socket)
    :ok = :gen_tcp.close(socket)

    {:ok, pid} = Bandit.start_link(plug: Treby.Test.AiSSEPlug, ip: {127, 0, 0, 1}, port: port)
    {pid, port}
  end
end
