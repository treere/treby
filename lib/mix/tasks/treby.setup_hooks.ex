defmodule Mix.Tasks.Treby.SetupHooks do
  @shortdoc "Installs git hooks (pre-push → mix precommit)"

  @moduledoc """
  Installs the pre-push hook that runs `mix precommit` before pushing.

  Mirrors CI checks: `format --check-formatted`, `credo --strict`,
  `treby.check_translations`, `treby.check_design_system`, `sobelow`,
  `compile --warnings-as-errors`, `test`.

  Source: `scripts/hooks/pre-push` → `.git/hooks/pre-push`
  """

  use Mix.Task

  @impl Mix.Task
  def run(_args) do
    root = File.cwd!()
    src = Path.join([root, "scripts", "hooks", "pre-push"])
    dest = Path.join([root, ".git", "hooks", "pre-push"])

    unless File.exists?(src) do
      Mix.raise("Hook source not found: #{src}")
    end

    File.mkdir_p!(Path.dirname(dest))
    File.cp!(src, dest)
    File.chmod!(dest, 0o755)
    Mix.shell().info("Installed pre-push hook → #{dest} (runs mix precommit)")
  end
end
