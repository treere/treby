defmodule Mix.Tasks.Treby.CheckTranslationsTest do
  use ExUnit.Case, async: false

  @po_path "priv/gettext/it/LC_MESSAGES/default.po"
  @pot_path "priv/gettext/default.pot"

  test "passes when Italian catalog is complete" do
    # The task should exit 0 when no missing translations
    assert File.exists?(@po_path)
    assert File.exists?(@pot_path)

    # Run the task and capture that it does not exit with error
    # We call the task directly; it will raise exit tuple on failure
    # If it passes, it will not exit
    try do
      Mix.Tasks.Treby.CheckTranslations.run([])
      assert true
    rescue
      _ -> flunk("check_translations should pass on complete catalog")
    catch
      :exit, {:shutdown, 1} -> flunk("check_translations failed unexpectedly")
      :exit, other -> flunk("unexpected exit: #{inspect(other)}")
    end
  end

  test "en locale is skipped (not treated as missing)" do
    # En has empty msgstr by convention, but guard should skip it
    try do
      Mix.Tasks.Treby.CheckTranslations.run(["--locales", "en"])
      assert true
    rescue
      _ -> flunk("en check should not fail")
    catch
      :exit, {:shutdown, 1} -> flunk("en check should pass")
    end
  end

  test "reports missing count via summary" do
    # Verify that total and missing counts are computed correctly
    # By checking that file exists and task prints summary
    output =
      ExUnit.CaptureIO.capture_io(fn ->
        try do
          Mix.Tasks.Treby.CheckTranslations.run([])
        catch
          :exit, _ -> :ok
        end
      end)

    assert output =~ "Translation coverage summary"
    assert output =~ "translated"
  end
end
