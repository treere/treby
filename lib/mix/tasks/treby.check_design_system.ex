defmodule Mix.Tasks.Treby.CheckDesignSystem do
  @shortdoc "Checks that no hardcoded design-system styles remain outside the DS"

  @moduledoc """
  Guardrail for design-system usage.

  Fails if any file under `lib/treby_web` (excluding `lib/treby_web/components/design_system/*`)
  contains copied card/input/table/modal/badge markup that should use the
  design system (`TrebyWeb.DesignSystem.*` + core `<.table>`/`<.input>`).

  Named patterns (reported as `file: pattern-name`):
  - `hardcoded-button`: `bg-blue-600`/`bg-green-600`/`bg-purple-600`/`bg-red-600`
    button remnants, `bg-gray-500`, daisyUI `btn btn-primary` / `badge badge-` /
    `table-zebra` contracts
  - `copied-card-shell`: `bg-white dark:bg-zinc-800 rounded-xl border` outside DS
  - `raw-table`: `<table[ >]` outside DS/core (exception: `comparison_live`,
    a transposed matrix that does not fit core `<.table>`)
  - `raw-modal-shell`: `fixed inset-0 z-50` dialog shells outside DS
    (z-40 nav scrims and bottom-sheet composers are not dialogs)
  - `raw-input`: bare `<input|select|textarea class=` in files without
    `input_classes|select_classes|textarea_classes|filter_bar|<.input`
    (checkbox/radio/hidden inputs are exempt — no DS helper covers them)
  - `copied-badge`: pale `bg-(emerald|amber|red|blue)-(50|100|950)` pill spans
    (`rounded-full` both orders) or inline status-to-variant `case` maps /
    `badge_variant` helpers outside DS — use `<.status_badge>` instead
  """

  use Mix.Task

  @patterns [
    hardcoded_button: ~r/bg-blue-600.*text-white.*(?:px-3|px-4).*rounded/,
    hardcoded_button: ~r/bg-green-600.*text-white/,
    hardcoded_button: ~r/bg-purple-600.*text-white/,
    hardcoded_button: ~r/bg-red-600.*text-white.*rounded/,
    hardcoded_button: ~r/class="[^"]*bg-gray-500[^"]*"/,
    hardcoded_button: ~r/btn btn-primary|badge badge-|table-zebra|radio radio-sm|select-sm/,
    copied_card_shell: ~r/bg-white dark:bg-zinc-800 rounded-xl border/,
    raw_table: ~r/<table[ >]/,
    raw_modal_shell: ~r/fixed inset-0 z-50/,
    copied_badge: ~r/case.*status.*(emerald|amber|red|blue)|badge_variant/
  ]

  # Badge-shaped pills: a class string combining rounded-full with a pale
  # status tint and text styling. Icon circles (p-2, no text), progress fills
  # (h-full), status dots (solid -500) and alert banners (rounded-lg) do not
  # match; use <.status_badge> / <.badge> instead.
  @pill_class ~r/class="[^"\n]*"/
  @pill_pale ~r/bg-(emerald|amber|red|blue)-(50|100|950)(?!\d)/

  # Bare form controls without DS tokens. Checkbox/radio/hidden inputs are
  # exempt (no DS helper covers them); anything styled with the zinc/orange
  # tokens — directly or via input_classes/select_classes/textarea_classes,
  # <.input>, filter_bar — passes.
  @raw_input_tag ~r/<(select|textarea)[^>]*class="(?![^"]*(zinc-|orange-))[^"]*"|<input(?![^>]*type="(checkbox|radio|hidden)")[^>]*class="(?![^"]*(zinc-|orange-))[^"]*"/

  @ds_module_file "lib/treby_web/components/design_system.ex"

  @exclude_regex ~r{lib/treby_web/components/design_system/}
  # DS building blocks themselves + the one documented non-fit (transposed
  # comparison matrix). Narrowly scoped per pattern below.
  @core_table_file "lib/treby_web/components/core_components.ex"
  @comparison_file "lib/treby_web/live/comparison_live/index.ex"

  @impl Mix.Task
  def run(_args) do
    files =
      Path.wildcard("lib/treby_web/**/*.{ex,heex}")
      |> Enum.reject(&Regex.match?(@exclude_regex, &1))

    offenders =
      Enum.flat_map(files, fn file ->
        content = File.read!(file)
        regex_hits(file, content) ++ raw_input_hits(file, content) ++ pill_hits(file, content)
      end)

    if offenders == [] do
      Mix.shell().info("Design-system guard: ok (no hardcoded styles found)")
    else
      Mix.shell().error("Design-system guard: hardcoded styles found outside DS:")

      for {file, name} <- Enum.uniq(offenders) do
        Mix.shell().error("  #{file}: #{name}")
      end

      Mix.shell().error(
        "Use TrebyWeb.DesignSystem.Button/Badge/Card/Modal/Pattern, <.status_badge>, <.table>, <.input> or input_classes/select_classes/textarea_classes instead (see lib/treby_web/components/design_system.ex)"
      )

      exit({:shutdown, 1})
    end
  end

  defp regex_hits(file, content) do
    for {name, pattern} <- @patterns,
        Regex.match?(pattern, content),
        not exempt?(file, name),
        do: {file, name}
  end

  defp exempt?(file, name)
       when name in [:copied_card_shell, :raw_table] and
              file in [@core_table_file, @comparison_file],
       do: true

  # badge_classes/1 definitions legitimately pair rounded-full with the pale
  # status tokens on one line.
  defp exempt?(file, :copied_badge) when file == @ds_module_file, do: true

  defp exempt?(_, _), do: false

  defp raw_input_hits(file, content) do
    if Regex.match?(@raw_input_tag, content) do
      [{file, :raw_input}]
    else
      []
    end
  end

  defp pill_hits(file, content) do
    pills =
      @pill_class
      |> Regex.scan(content)
      |> List.flatten()
      |> Enum.filter(fn cls ->
        String.contains?(cls, "rounded-full") and Regex.match?(@pill_pale, cls) and
          String.contains?(cls, "text-")
      end)

    if pills != [] and file != @ds_module_file, do: [{file, :copied_badge}], else: []
  end
end
