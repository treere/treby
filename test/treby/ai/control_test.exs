defmodule Treby.AI.ControlTest do
  use ExUnit.Case, async: true

  alias Treby.AI.Control

  describe "parse_verdict/2 (unit)" do
    test "pass keeps the reviewed reply" do
      raw = Jason.encode!(%{"verdict" => "pass", "reply" => "ok", "reason" => "fine"})
      assert Control.parse_verdict(raw, "orig") == {:ok, :pass, "ok"}
    end

    test "block returns an empty reply" do
      raw = Jason.encode!(%{"verdict" => "block", "reply" => "", "reason" => "leak"})
      assert Control.parse_verdict(raw, "orig") == {:ok, :block, ""}
    end

    test "sanitize returns the cleaned reply" do
      raw = Jason.encode!(%{"verdict" => "sanitize", "reply" => "cleaned", "reason" => "pii"})
      assert Control.parse_verdict(raw, "orig") == {:ok, :sanitize, "cleaned"}
    end

    test "unparseable output falls back to pass with the original" do
      assert Control.parse_verdict("not json", "orig") == {:ok, :pass, "orig"}
      assert Control.parse_verdict("", "orig") == {:ok, :pass, "orig"}
    end
  end

  describe "evaluate/2 (injected generator)" do
    test "passes through when the reviewer returns a normal reply" do
      gen = fn _msgs ->
        {:ok, Jason.encode!(%{"verdict" => "pass", "reply" => "ok", "reason" => ""})}
      end

      assert Control.evaluate("orig", %{}, generate: gen) == {:ok, :pass, "ok"}
    end

    test "blocks an inappropriate reply" do
      gen = fn _msgs ->
        {:ok, Jason.encode!(%{"verdict" => "block", "reply" => "", "reason" => "leak"})}
      end

      assert {:ok, :block, ""} = Control.evaluate("leaky reply", %{}, generate: gen)
    end

    test "sanitizes a reply" do
      gen = fn _msgs ->
        {:ok, Jason.encode!(%{"verdict" => "sanitize", "reply" => "clean", "reason" => "pii"})}
      end

      assert {:ok, :sanitize, "clean"} = Control.evaluate("messy reply", %{}, generate: gen)
    end

    test "fails open to pass on a non-JSON reviewer output" do
      gen = fn _msgs -> {:ok, "not json at all"} end
      assert Control.evaluate("orig", %{}, generate: gen) == {:ok, :pass, "orig"}
    end

    test "fails open to pass when the reviewer errors" do
      gen = fn _msgs -> {:error, :boom} end
      assert Control.evaluate("orig", %{}, generate: gen) == {:ok, :pass, "orig"}
    end

    test "empty input is a pass without calling the reviewer" do
      gen = fn _msgs -> flunk("reviewer must not be called for empty input") end
      assert Control.evaluate("", %{}, generate: gen) == {:ok, :pass, ""}
    end
  end
end
