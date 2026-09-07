defmodule Treby.Helpers.MapTest do
  use ExUnit.Case, async: true

  alias Treby.Helpers.Map, as: HelpersMap

  test "stringify_keys/1 converts atom keys to strings" do
    assert HelpersMap.stringify_keys(%{:a => 1, "b" => 2}) == %{"a" => 1, "b" => 2}
  end

  test "stringify_keys/1 is idempotent" do
    once = HelpersMap.stringify_keys(%{:a => 1})
    assert HelpersMap.stringify_keys(once) == once
  end

  test "stringify_keys/1 stringifies values only for keys" do
    assert HelpersMap.stringify_keys(%{:a => :atom_value}) == %{"a" => :atom_value}
  end
end
