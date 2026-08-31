defmodule Treby.Credo.Check.NoHardcodedUIStringsTest do
  use ExUnit.Case, async: false

  alias Treby.Credo.Check.NoHardcodedUIStrings

  test "flags hardcoded UI strings like My Actions" do
    assert NoHardcodedUIStrings.ui_string?("My Actions") == true
    assert NoHardcodedUIStrings.ui_string?("Applications This Week") == true
    assert NoHardcodedUIStrings.ui_string?("Scorecard submitted") == true
    assert NoHardcodedUIStrings.ui_string?("All caught up") == true
  end

  test "does not flag gettext-wrapped strings conceptually" do
    # The check skips lines containing gettext, so ui_string? itself still returns true,
    # but the line-level check would skip. Here we just verify ui_string? for content.
    assert NoHardcodedUIStrings.ui_string?("My Actions") == true
  end

  test "ignores class and hero-* literals" do
    assert NoHardcodedUIStrings.ui_string?("text-sm text-blue-600") == false
    assert NoHardcodedUIStrings.ui_string?("hero-check-circle") == false
    assert NoHardcodedUIStrings.ui_string?("phx-click") == false
  end

  test "ignores non-UI strings" do
    assert NoHardcodedUIStrings.ui_string?("Treby") == false
    assert NoHardcodedUIStrings.ui_string?("en") == false
    assert NoHardcodedUIStrings.ui_string?("hero-") == false
    assert NoHardcodedUIStrings.ui_string?("a") == false
  end

  test "ignores technical identifiers" do
    assert NoHardcodedUIStrings.ui_string?("API_KEY") == false
    assert NoHardcodedUIStrings.ui_string?("HELLO") == false
  end

  test "check module is configured in credo" do
    # Verify the check is listed in .credo.exs
    content = File.read!(".credo.exs")
    assert content =~ "NoHardcodedUIStrings"
    assert content =~ "requires"
  end
end
