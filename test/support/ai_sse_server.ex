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

defmodule Treby.Test.AiFormFillPlug do
  @moduledoc false
  @behaviour Plug

  import Plug.Conn

  @tool_events [
    %{
      "choices" => [
        %{
          "delta" => %{
            "role" => "assistant",
            "tool_calls" => [
              %{
                "index" => 0,
                "id" => "call_form_1",
                "type" => "function",
                "function" => %{"name" => "propose_form_fill", "arguments" => ""}
              }
            ]
          }
        }
      ]
    },
    %{
      "choices" => [
        %{
          "delta" => %{
            "tool_calls" => [
              %{"index" => 0, "function" => %{"arguments" => "{\"values\":{\"title\":\"X\"}}"}}
            ]
          }
        }
      ]
    },
    %{"choices" => [%{"delta" => %{}, "finish_reason" => "tool_calls"}]}
  ]

  @final_events [
    %{"choices" => [%{"delta" => %{"content" => "Done"}}]},
    %{"choices" => [%{"delta" => %{}, "finish_reason" => "stop"}]}
  ]

  @impl Plug
  def init(opts), do: opts

  @impl Plug
  def call(conn, _opts) do
    {:ok, body, conn} = read_body(conn)
    saw_tool = body =~ ~s("role":"tool")

    events = if saw_tool, do: @final_events, else: @tool_events

    conn
    |> put_resp_content_type("text/event-stream")
    |> send_chunked(200)
    |> then(fn conn ->
      conn =
        Enum.reduce(events, conn, fn event, conn ->
          {:ok, conn} = chunk(conn, "data: #{Jason.encode!(event)}\n\n")
          conn
        end)

      {:ok, conn} = chunk(conn, "data: [DONE]\n\n")
      conn
    end)
  end
end

defmodule Treby.Test.AiFormFillServer do
  @moduledoc false

  def start do
    {:ok, socket} = :gen_tcp.listen(0, [:binary, ip: {127, 0, 0, 1}, active: false])
    {:ok, port} = :inet.port(socket)
    :ok = :gen_tcp.close(socket)

    {:ok, pid} =
      Bandit.start_link(plug: Treby.Test.AiFormFillPlug, ip: {127, 0, 0, 1}, port: port)

    {pid, port}
  end
end

defmodule Treby.Test.AiJsonPlug do
  @moduledoc false
  @behaviour Plug

  import Plug.Conn

  def init(opts), do: opts

  def call(conn, opts) do
    text = Keyword.get(opts, :text, "Ciao mondo")

    events =
      [
        %{"choices" => [%{"delta" => %{"role" => "assistant"}, "index" => 0}]},
        %{"choices" => [%{"delta" => %{"content" => text}, "index" => 0}]},
        %{"choices" => [%{"delta" => %{}, "index" => 0, "finish_reason" => "stop"}]}
      ]

    conn
    |> put_resp_content_type("text/event-stream")
    |> send_chunked(200)
    |> then(fn conn ->
      conn =
        Enum.reduce(events, conn, fn event, conn ->
          Process.sleep(20)
          {:ok, conn} = chunk(conn, "data: #{Jason.encode!(event)}\n\n")
          conn
        end)

      {:ok, conn} = chunk(conn, "data: [DONE]\n\n")
      conn
    end)
  end
end

defmodule Treby.Test.AiJsonServer do
  @moduledoc false

  def start(text) do
    {:ok, socket} = :gen_tcp.listen(0, [:binary, ip: {127, 0, 0, 1}, active: false])
    {:ok, port} = :inet.port(socket)
    :ok = :gen_tcp.close(socket)

    {:ok, pid} =
      Bandit.start_link(
        plug: {Treby.Test.AiJsonPlug, [text: text]},
        ip: {127, 0, 0, 1},
        port: port
      )

    {pid, port}
  end
end
