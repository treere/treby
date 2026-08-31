defmodule Mix.Tasks.Treby.CheckTranslations do
  use Mix.Task

  @shortdoc "Checks that Italian translations are complete and POT is fresh"

  @moduledoc """
  Checks translation coverage for supported locales.

  Compares `priv/gettext/default.pot` (and `errors.pot`) against
  `priv/gettext/<locale>/LC_MESSAGES/*.po` and fails when any
  non-header `msgid` has an empty `msgstr`.

  ## Usage

      mix treby.check_translations
      mix treby.check_translations --locales it
      mix treby.check_translations --check-pot
      mix treby.check_translations --pot priv/gettext/default.pot --po priv/gettext/it/LC_MESSAGES/default.po

  ## Options

    * `--locales` - comma-separated locales to check (default: `it`)
    * `--pot` - path to POT file (default: `priv/gettext/default.pot`)
    * `--po` - path to PO file (default: derived from locale)
    * `--check-pot` - also verify POT is up-to-date with source (runs `mix gettext.extract` to a temp check)
    * `--help` - show this help

  Exits with status 0 when all `it` translations are present and POT is fresh,
  status 1 otherwise. `en` empty `msgstr` is intentionally not treated as failure.
  """

  @default_locales ["it"]
  @default_pot "priv/gettext/default.pot"
  @default_errors_pot "priv/gettext/errors.pot"

  @impl Mix.Task
  def run(args) do
    {opts, _, _} =
      OptionParser.parse(args,
        strict: [locales: :string, pot: :string, po: :string, check_pot: :boolean, help: :boolean],
        aliases: [h: :help]
      )

    if opts[:help] do
      Mix.shell().info(@moduledoc)
      exit({:shutdown, 0})
    end

    locales =
      case opts[:locales] do
        nil -> @default_locales
        str -> String.split(str, ",", trim: true) |> Enum.map(&String.trim/1)
      end

    check_pot? = !!opts[:check_pot]

    # POT staleness check first if requested
    if check_pot? do
      check_pot_freshness!()
    end

    results =
      for locale <- locales do
        check_locale(locale, opts)
      end

    total_missing = Enum.sum(Enum.map(results, & &1.missing))
    total = Enum.sum(Enum.map(results, & &1.total))

    Mix.shell().info("")
    Mix.shell().info("Translation coverage summary:")

    for r <- results do
      pct = if r.total == 0, do: 100, else: round(r.translated / r.total * 100)

      Mix.shell().info(
        "  #{r.locale}: #{r.translated}/#{r.total} translated (#{pct}%), #{r.missing} missing"
      )
    end

    Mix.shell().info(
      "  overall: #{total - total_missing}/#{total} translated, #{total_missing} missing"
    )

    if total_missing > 0 do
      Mix.shell().error("\nMissing translations detected:")

      for r <- results, entry <- r.missing_entries do
        refs = if entry.refs == [], do: "", else: " (#{Enum.join(entry.refs, ", ")})"
        Mix.shell().error("  [#{r.locale}] msgid \"#{entry.msgid}\"#{refs} -> msgstr is empty")
      end

      Mix.shell().error(
        "\nRun `mix gettext.extract --merge` and fill `priv/gettext/it/LC_MESSAGES/*.po` for the missing keys."
      )

      exit({:shutdown, 1})
    else
      Mix.shell().info("\nAll translations complete.")
    end
  end

  defp check_locale(locale, opts) do
    # Skip completeness check for `en` if only checking `en` – treat as always passing
    # But spec says `en` empty msgstr is OK; we still parse but don't count as missing when locale == "en"
    if locale == "en" do
      %{locale: locale, total: 0, translated: 0, missing: 0, missing_entries: []}
    else
      # Determine POT/PO pairs to check: default + errors
      pairs = pot_po_pairs(locale, opts)

      all_missing =
        Enum.flat_map(pairs, fn {pot_path, po_path} ->
          pot_entries = parse_po_file(pot_path, :pot)
          po_entries = parse_po_file(po_path, :po)

          # Build map from msgid -> po entry for quick lookup
          po_map = Map.new(po_entries, fn e -> {e.msgid, e} end)

          # For each POT entry with non-empty msgid, check PO has non-empty msgstr
          Enum.flat_map(pot_entries, fn pot_entry ->
            if pot_entry.msgid == "" do
              []
            else
              case Map.get(po_map, pot_entry.msgid) do
                nil ->
                  [%{msgid: pot_entry.msgid, refs: pot_entry.refs}]

                po_entry ->
                  cond do
                    pot_entry.plural? ->
                      # Plural entry: check all msgstr[N] are non-empty
                      if po_entry.msgstr_plural == [] do
                        # No plural translations – treat as missing if singular msgstr empty
                        if String.trim(po_entry.msgstr) == "" do
                          [%{msgid: pot_entry.msgid, refs: pot_entry.refs}]
                        else
                          []
                        end
                      else
                        missing_plural? =
                          Enum.any?(po_entry.msgstr_plural, fn s -> String.trim(s) == "" end)

                        if missing_plural?,
                          do: [%{msgid: pot_entry.msgid, refs: pot_entry.refs}],
                          else: []
                      end

                    true ->
                      if String.trim(po_entry.msgstr) == "" do
                        [%{msgid: pot_entry.msgid, refs: pot_entry.refs}]
                      else
                        []
                      end
                  end
              end
            end
          end)
        end)

      # Total is total POT entries (non-header) across pairs
      total =
        Enum.sum(
          Enum.map(pairs, fn {pot_path, _} ->
            pot_entries = parse_po_file(pot_path, :pot)
            Enum.count(pot_entries, fn e -> e.msgid != "" end)
          end)
        )

      translated = total - length(all_missing)

      %{
        locale: locale,
        total: total,
        translated: translated,
        missing: length(all_missing),
        missing_entries: all_missing
      }
    end
  end

  defp pot_po_pairs(locale, opts) do
    # If explicit --pot/--po given, use single pair
    if opts[:pot] || opts[:po] do
      pot = opts[:pot] || @default_pot
      po = opts[:po] || "priv/gettext/#{locale}/LC_MESSAGES/default.po"
      [{pot, po}]
    else
      [
        {@default_pot, "priv/gettext/#{locale}/LC_MESSAGES/default.po"},
        {@default_errors_pot, "priv/gettext/#{locale}/LC_MESSAGES/errors.po"}
      ]
      |> Enum.filter(fn {pot, po} -> File.exists?(pot) and File.exists?(po) end)
    end
  end

  defp parse_po_file(path, _kind) do
    case File.read(path) do
      {:ok, content} -> parse_entries(content)
      {:error, _} -> []
    end
  end

  defp parse_entries(content) do
    # Split on blank lines (entries separated by at least one empty line)
    # Keep refs (#: ...) together with msgid/msgstr
    content
    |> String.split(~r/\n\s*\n/, trim: true)
    |> Enum.map(&parse_entry/1)
    |> Enum.reject(&is_nil/1)
  end

  defp parse_entry(block) do
    lines = String.split(block, "\n")

    refs =
      lines
      |> Enum.filter(&String.starts_with?(String.trim_leading(&1), "#:"))
      |> Enum.flat_map(fn line ->
        line
        |> String.trim_leading()
        |> String.trim_leading("#:")
        |> String.trim()
        |> String.split(~r/\s+/, trim: true)
      end)

    # State machine for msgid/msgstr with possible multi-line quoted strings and plural forms
    {msgid, msgstr, msgstr_plural, plural?, _state} =
      Enum.reduce(lines, {nil, nil, [], false, nil}, fn line,
                                                        {msgid_acc, msgstr_acc, plural_acc,
                                                         is_plural, state} ->
        trimmed = String.trim_leading(line)

        cond do
          String.starts_with?(trimmed, "msgid_plural") ->
            {msgid_acc, msgstr_acc, plural_acc, true, :msgid_plural}

          String.starts_with?(trimmed, "msgid ") or trimmed == "msgid \"\"" ->
            quoted =
              extract_quoted(trimmed |> String.replace_prefix("msgid", "") |> String.trim())

            {quoted, msgstr_acc, plural_acc, is_plural, :msgid}

          String.starts_with?(trimmed, "msgstr[") ->
            # msgstr[0] "..." etc
            quoted = extract_quoted(trimmed)
            {msgid_acc, msgstr_acc, plural_acc ++ [quoted], true, :msgstr_plural}

          String.starts_with?(trimmed, "msgstr ") or trimmed == "msgstr \"\"" ->
            quoted =
              extract_quoted(trimmed |> String.replace_prefix("msgstr", "") |> String.trim())

            {msgid_acc, quoted, plural_acc, is_plural, :msgstr}

          String.starts_with?(trimmed, "\"") and state == :msgid ->
            extra = extract_quoted(trimmed)
            {(msgid_acc || "") <> extra, msgstr_acc, plural_acc, is_plural, :msgid}

          String.starts_with?(trimmed, "\"") and state == :msgstr ->
            extra = extract_quoted(trimmed)
            {msgid_acc, (msgstr_acc || "") <> extra, plural_acc, is_plural, :msgstr}

          String.starts_with?(trimmed, "\"") and state == :msgstr_plural ->
            extra = extract_quoted(trimmed)
            # Append to last plural entry
            updated =
              case plural_acc do
                [] -> [extra]
                list -> List.update_at(list, -1, &(&1 <> extra))
              end

            {msgid_acc, msgstr_acc, updated, is_plural, :msgstr_plural}

          String.starts_with?(trimmed, "\"") and state == :msgid_plural ->
            extra = extract_quoted(trimmed)
            {(msgid_acc || "") <> extra, msgstr_acc, plural_acc, is_plural, :msgid_plural}

          true ->
            {msgid_acc, msgstr_acc, plural_acc, is_plural, state}
        end
      end)

    if is_nil(msgid) and is_nil(msgstr) and msgstr_plural == [] do
      nil
    else
      %{
        msgid: msgid || "",
        msgstr: msgstr || "",
        msgstr_plural: msgstr_plural,
        plural?: plural?,
        refs: refs
      }
    end
  end

  defp extract_quoted(str) do
    # Extract all "..." quoted segments and unescape, then concat
    ~r/"((?:[^"\\]|\\.)*)"/
    |> Regex.scan(str)
    |> Enum.map(fn [_, inner] -> unescape(inner) end)
    |> Enum.join()
  end

  defp unescape(str) do
    str
    |> String.replace("\\n", "\n")
    |> String.replace("\\t", "\t")
    |> String.replace("\\\"", "\"")
    |> String.replace("\\\\", "\\")
  end

  defp check_pot_freshness! do
    Mix.shell().info("Checking POT freshness (running `mix gettext.extract` to temp)...")

    pot_path = @default_pot
    errors_pot_path = @default_errors_pot

    original_pot =
      case File.read(pot_path) do
        {:ok, c} -> c
        _ -> ""
      end

    original_errors =
      case File.read(errors_pot_path) do
        {:ok, c} -> c
        _ -> ""
      end

    # Run extraction; it will overwrite POT files
    {output, exit_code} = System.cmd("mix", ["gettext.extract"], stderr_to_stdout: true)

    fresh_pot =
      case File.read(pot_path) do
        {:ok, c} -> c
        _ -> ""
      end

    fresh_errors =
      case File.read(errors_pot_path) do
        {:ok, c} -> c
        _ -> ""
      end

    # Restore originals regardless
    File.write!(pot_path, original_pot)
    if File.exists?(errors_pot_path), do: File.write!(errors_pot_path, original_errors)

    if exit_code != 0 do
      Mix.shell().error("`mix gettext.extract` failed:\n#{output}")
      exit({:shutdown, 1})
    end

    if original_pot != fresh_pot or original_errors != fresh_errors do
      Mix.shell().error("""
      POT is stale — source contains gettext strings not in POT.
      Run `mix gettext.extract --merge` and commit the updated POT/PO files.
      """)

      # Show diff hint: list msgids that are new
      new_entries = parse_entries(fresh_pot) |> MapSet.new(& &1.msgid)
      old_entries = parse_entries(original_pot) |> MapSet.new(& &1.msgid)
      added = MapSet.difference(new_entries, old_entries) |> MapSet.delete("") |> Enum.to_list()

      if added != [] do
        Mix.shell().error("New msgids not in POT:")

        for msgid <- Enum.take(added, 20) do
          Mix.shell().error("  + \"#{msgid}\"")
        end

        if length(added) > 20 do
          Mix.shell().error("  ... and #{length(added) - 20} more")
        end
      end

      exit({:shutdown, 1})
    else
      Mix.shell().info("POT is fresh.")
    end
  end
end
