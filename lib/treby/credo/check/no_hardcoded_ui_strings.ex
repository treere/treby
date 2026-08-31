defmodule Treby.Credo.Check.NoHardcodedUIStrings do
  @moduledoc """
  Flags hardcoded user-facing strings in LiveViews, components, and controllers
  that are not wrapped in `gettext`/`ngettext`/`dgettext`.

  The check scans `lib/treby_web/live/**`, `lib/treby_web/components/**`,
  and `lib/treby_web/controllers/**` for:

  - quoted string literals like `"My Actions"` outside a `gettext` call
  - raw HEEx text nodes like `>Dashboard<` between HTML tags

  Allowlist: `class`, `id`, `phx-*`, `hero-*`, `data-*` attribute values are
  ignored because they are lowercase/dashed. Strings containing `gettext`,
  `ngettext`, `dgettext`, or `gettext_noop` are ignored. Lines with
  `credo:disable` are ignored. The brand string `"Treby"` is allowed without
  translation (use escape hatch `credo:disable-for-next-line` if needed).

  Triggered strings should be wrapped with `gettext("...")` or
  `gettext("...", var: value)` for interpolation.
  """

  @explanation [
    check: @moduledoc,
    params: []
  ]

  use Credo.Check, base_priority: :high, category: :warning, exit_status: 0

  @relevant_paths [
    "lib/treby_web/live/",
    "lib/treby_web/components/",
    "lib/treby_web/controllers/"
  ]

  # Regex for quoted strings containing plausible UI text (capitalized)
  # We scan all "..." then filter with ui_string?/1
  @quoted_regex ~r/"([^"]+)"/
  @text_node_regex ~r/>[^<]*?([A-Z][a-z][^<]*?)</

  @doc false
  @impl true
  def run(%Credo.SourceFile{} = source_file, params) do
    filename = source_file.filename

    if not relevant_file?(filename) do
      []
    else
      lines = Credo.SourceFile.lines(source_file)
      source = Credo.SourceFile.source(source_file)
      gettext_strings = extract_gettext_strings(source)
      issue_meta = Credo.IssueMeta.for(source_file, params)

      Enum.reduce(lines, [], fn {line_no, line}, acc ->
        case find_hardcoded(line, gettext_strings) do
          nil -> acc
          trigger -> [issue_for(issue_meta, line_no, trigger, line) | acc]
        end
      end)
    end
  end

  defp extract_gettext_strings(source) when is_binary(source) do
    # Extract all strings inside gettext/dgettext/ngettext calls, handling multiline
    # Matches gettext("...") , gettext("...", ...) , dgettext("domain", "...") etc.
    ~r/(?:gettext|dgettext|ngettext|dngettext)\s*\(\s*(?:\"[^\"]*\"\s*,\s*)?\"([^\"]+)\"/
    |> Regex.scan(source)
    |> Enum.map(fn [_, inner] -> inner end)
    |> MapSet.new()
  end

  defp extract_gettext_strings(_), do: MapSet.new()

  defp relevant_file?(filename) when is_binary(filename) do
    # Exclude design system / dev-only components and the check itself
    if String.contains?(filename, "design_system") or
         String.contains?(filename, "lib/treby/credo") or
         String.contains?(filename, "no_hardcoded") do
      false
    else
      Enum.any?(@relevant_paths, &String.contains?(filename, &1))
    end
  end

  defp relevant_file?(_), do: false

  defp find_hardcoded(line, gettext_strings) do
    trimmed = String.trim(line)

    cond do
      # Skip empty or comment-ish lines
      trimmed == "" ->
        nil

      String.starts_with?(trimmed, "#") ->
        nil

      # Escape hatch
      String.contains?(line, "credo:disable") ->
        nil

      # Already wrapped in gettext (including multiline where string is on next line after gettext()
      String.contains?(line, "gettext") ->
        nil

      # Skip module / directive lines that are not UI
      String.contains?(line, "defmodule") ->
        nil

      String.contains?(line, "alias ") ->
        nil

      String.contains?(line, "import ") ->
        nil

      String.contains?(line, "@moduledoc") ->
        nil

      String.contains?(line, "Logger.") ->
        nil

      String.contains?(line, "Hardcoded UI string") ->
        nil

      true ->
        # Check quoted strings first (skip if already inside a gettext call anywhere in file)
        quoted_trigger = find_quoted_trigger(line, gettext_strings)

        if quoted_trigger do
          quoted_trigger
        else
          find_text_node_trigger(line)
        end
    end
  end

  defp find_quoted_trigger(line, gettext_strings) do
    # Find all quoted substrings and check each
    # Only consider quoted strings that contain a space (multi-word) to reduce noise
    # Single-word capitalized strings are caught via text-node detection when appropriate
    Regex.scan(@quoted_regex, line)
    |> Enum.map(fn [_, inner] -> inner end)
    |> Enum.find(fn str ->
      String.contains?(str, " ") and ui_string?(str) and not MapSet.member?(gettext_strings, str)
    end)
  end

  defp find_text_node_trigger(line) do
    # Look for >Text< patterns (HEEx text nodes)
    case Regex.run(@text_node_regex, line) do
      nil ->
        nil

      [_, inner] ->
        inner = String.trim(inner)

        if ui_string?(inner) and not String.contains?(inner, "{") and
             not String.contains?(inner, "}") do
          inner
        else
          nil
        end

      _ ->
        nil
    end
  end

  def ui_string?(str) when is_binary(str) do
    trimmed = String.trim(str)

    cond do
      String.length(trimmed) < 3 -> false
      trimmed == "Treby" -> false
      # Technical identifiers: hero-*, phx-*, data-*
      String.contains?(trimmed, "hero-") -> false
      String.contains?(trimmed, "phx-") -> false
      String.contains?(trimmed, "data-") -> false
      # File paths or technical values with slash/backslash
      String.contains?(trimmed, "/") and String.contains?(trimmed, ".") -> false
      String.contains?(trimmed, "\\") -> false
      # All caps or snake_case constants
      Regex.match?(~r/^[A-Z0-9_]+$/, trimmed) -> false
      # Must start with capital and contain a letter
      not Regex.match?(~r/^[A-Z][a-z]/, trimmed) -> false
      # Contains at least one lowercase letter after capital
      not Regex.match?(~r/[a-z]/, trimmed) -> false
      # Exclude strings that are clearly code-like (contain =>, ->, :, | etc. without spaces)
      String.contains?(trimmed, "=>") -> false
      # For single-word like "Dashboard", we allow if length >=4 and capitalized
      # For multi-word, allow as well
      true -> true
    end
  end

  def ui_string?(_), do: false

  defp issue_for(issue_meta, line_no, trigger, line) do
    column = find_column(line, trigger)

    format_issue(issue_meta,
      message: "Hardcoded UI string outside gettext — wrap with gettext(\"#{trigger}\")",
      line_no: line_no,
      column: column,
      trigger: trigger
    )
  end

  defp find_column(line, trigger) do
    case :binary.match(line, trigger) do
      {pos, _} -> pos + 1
      :nomatch -> nil
    end
  end
end
