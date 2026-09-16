defmodule Treby.AI.RouterTest do
  use Treby.DataCase, async: false

  alias Treby.AI.Router
  alias Treby.Test.AiSSE.Server, as: AiSSEServer

  describe "parse_classification/2 (unit)" do
    test "maps a single domain word to its atom" do
      assert Router.parse_classification("recruiter", :analytics) == :recruiter
      assert Router.parse_classification("COMMS", :recruiter) == :comms
    end

    test "takes the first word when extra text is present" do
      assert Router.parse_classification("analytics please", :recruiter) == :analytics
      assert Router.parse_classification("comms now", :recruiter) == :comms
    end

    test "falls back to last_domain on unknown output" do
      assert Router.parse_classification("not a domain", :comms) == :comms
      assert Router.parse_classification("", :analytics) == :analytics
    end

    test "falls back to :recruiter when there is no last domain" do
      assert Router.parse_classification("garbage", nil) == :recruiter
      assert Router.parse_classification("", nil) == :recruiter
    end
  end

  describe "classify/3 (sticky + fallback)" do
    setup do
      {server_pid, port} = AiSSEServer.start()
      on_exit(fn -> Process.exit(server_pid, :shutdown) end)

      previous = Application.get_env(:treby, :ai, [])

      Application.put_env(
        :treby,
        :ai,
        previous
        |> Keyword.merge(base_url: "http://127.0.0.1:#{port}/v1", api_key: "test", model: "m")
      )

      on_exit(fn -> Application.put_env(:treby, :ai, previous) end)

      :ok
    end

    test "keeps the last domain when the model output is not a domain" do
      assert Router.classify([], "do the hiring thing", :analytics) == :analytics
      assert Router.classify([], "schedule a message", :comms) == :comms
    end

    test "falls back to :recruiter when no last domain is set" do
      assert Router.classify([], "hello there", nil) == :recruiter
    end
  end
end
