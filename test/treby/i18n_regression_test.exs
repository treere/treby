defmodule Treby.I18nRegressionTest do
  use ExUnit.Case, async: false

  alias Mix.Tasks.Treby.CheckTranslations

  @it_po "priv/gettext/it/LC_MESSAGES/default.po"
  @it_errors "priv/gettext/it/LC_MESSAGES/errors.po"
  @pot "priv/gettext/default.pot"

  test "Italian catalog has zero empty msgstr after extraction" do
    assert File.exists?(@it_po), "IT PO should exist"
    assert File.exists?(@pot), "POT should exist"

    content = File.read!(@it_po)
    # Count empty msgstr entries excluding header
    # Use the same parser as the mix task to be consistent
    blocks = String.split(content, ~r/\n\s*\n/, trim: true)

    empty_count =
      Enum.count(blocks, fn block ->
        # Check if it's truly empty (no continuation with content)
        String.contains?(block, "msgid \"") and not String.contains?(block, "msgid \"\"") and
          Regex.match?(~r/msgstr\s+""/, block) and not String.contains?(block, "msgstr[") and
          not Regex.match?(~r/msgstr ""\n"[^"]+"/, block)
      end)

    assert empty_count == 0,
           "Expected 0 empty msgstr in IT catalog, found #{empty_count}. Run mix gettext.extract --merge and fill translations."
  end

  test "errors catalog is complete" do
    assert File.exists?(@it_errors)
    content = File.read!(@it_errors)
    # Should have translations for plural forms
    assert content =~ "non può essere vuoto"
    # No empty msgstr for non-plural
    blocks = String.split(content, ~r/\n\s*\n/, trim: true)

    empty_singular =
      Enum.count(blocks, fn block ->
        String.contains?(block, "msgid \"") and not String.contains?(block, "msgid \"\"") and
          not String.contains?(block, "msgstr[") and Regex.match?(~r/msgstr\s+""/, block)
      end)

    assert empty_singular == 0
  end

  test "mix treby.check_translations passes" do
    output =
      ExUnit.CaptureIO.capture_io(fn ->
        try do
          CheckTranslations.run([])
        catch
          :exit, _ -> :ok
        end
      end)

    assert output =~ "All translations complete" or output =~ "100%"
  end
end
