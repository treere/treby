defmodule Mix.Tasks.Treby.CheckDesignSystem do
  @shortdoc "Checks that no hardcoded design-system styles remain outside the DS"

  @moduledoc """
  Guardrail for design-system usage.

  Fails if any file under `lib/treby_web` (excluding `lib/treby_web/components/design_system/*`
  and `assets/css/app.css`) contains hardcoded button/badge styles that should use the
  design system (`TrebyWeb.DesignSystem.*`).

  Patterns checked:
  - `bg-blue-600.*text-white.*px-3.*rounded` / `bg-green-600` / `bg-purple-600` / `bg-red-600`
  - `bg-gray-500` button remnants
  - `bg-gray-50` / `bg-gray-900` surfaces (should be `base-*` tokens)
  """

  use Mix.Task

  @patterns [
    ~r/bg-blue-600.*text-white.*(?:px-3|px-4).*rounded/,
    ~r/bg-green-600.*text-white/,
    ~r/bg-purple-600.*text-white/,
    ~r/bg-red-600.*text-white.*rounded/,
    ~r/class="[^"]*bg-gray-500[^"]*"/
  ]

  @exclude_regex ~r{lib/treby_web/components/design_system/}

  @impl Mix.Task
  def run(_args) do
    files =
      Path.wildcard("lib/treby_web/**/*.{ex,heex}")
      |> Enum.reject(&Regex.match?(@exclude_regex, &1))

    offenders =
      for file <- files,
          content = File.read!(file),
          pattern <- @patterns,
          Regex.match?(pattern, content) do
        {file, pattern}
      end

    if offenders == [] do
      Mix.shell().info("Design-system guard: ok (no hardcoded styles found)")
    else
      Mix.shell().error("Design-system guard: hardcoded styles found outside DS:")

      for {file, pattern} <- Enum.uniq(offenders) do
        Mix.shell().error("  #{file}: matches #{inspect(pattern)}")
      end

      Mix.shell().error(
        "Use TrebyWeb.DesignSystem.Button/Badge/Card/Pattern instead (see lib/treby_web/components/design_system.ex)"
      )

      exit({:shutdown, 1})
    end
  end
end
