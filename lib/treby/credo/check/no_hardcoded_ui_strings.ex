if Code.ensure_loaded?(Credo.Check) do
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

      if relevant_file?(filename) do
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
      else
        []
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
      if skip_hardcoded_line?(line) do
        nil
      else
        quoted_trigger = find_quoted_trigger(line, gettext_strings)

        if quoted_trigger do
          quoted_trigger
        else
          find_text_node_trigger(line)
        end
      end
    end

    defp skip_hardcoded_line?(line) do
      trimmed = String.trim(line)

      trimmed == "" or
        String.starts_with?(trimmed, "#") or
        String.contains?(line, "credo:disable") or
        String.contains?(line, "gettext") or
        String.contains?(line, "defmodule") or
        String.contains?(line, "alias ") or
        String.contains?(line, "import ") or
        String.contains?(line, "@moduledoc") or
        String.contains?(line, "Logger.") or
        String.contains?(line, "Hardcoded UI string")
    end

    defp find_quoted_trigger(line, gettext_strings) do
      # Find all quoted substrings and check each
      # Only consider quoted strings that contain a space (multi-word) to reduce noise
      # Single-word capitalized strings are caught via text-node detection when appropriate
      Regex.scan(@quoted_regex, line)
      |> Enum.map(fn [_, inner] -> inner end)
      |> Enum.find(fn str ->
        String.contains?(str, " ") and ui_string?(str) and
          not MapSet.member?(gettext_strings, str)
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
      ui_string_valid?(trimmed)
    end

    def ui_string?(_), do: false

    defp ui_string_valid?(trimmed) do
      cond do
        String.length(trimmed) < 3 -> false
        trimmed == "Treby" -> false
        technical_ui_string?(trimmed) -> false
        not Regex.match?(~r/^[A-Z][a-z]/, trimmed) -> false
        not Regex.match?(~r/[a-z]/, trimmed) -> false
        String.contains?(trimmed, "=>") -> false
        true -> true
      end
    end

    defp technical_ui_string?(trimmed) do
      String.contains?(trimmed, "hero-") or
        String.contains?(trimmed, "phx-") or
        String.contains?(trimmed, "data-") or
        (String.contains?(trimmed, "/") and String.contains?(trimmed, ".")) or
        String.contains?(trimmed, "\\") or
        Regex.match?(~r/^[A-Z0-9_]+$/, trimmed)
    end

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
else
  defmodule Treby.Credo.Check.NoHardcodedUIStrings do
  end
end
