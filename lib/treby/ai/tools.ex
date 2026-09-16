defmodule Treby.AI.Tools do
  @moduledoc "Registry + shared helpers for the AI tools across domains."

  alias Treby.AI.Tools.{Shared, Recruiter, Analytics, Comms, Admin}

  @registries [Recruiter, Analytics, Comms, Admin, Shared]

  @doc "All registered tool modules (every domain + shared)."
  def all, do: Enum.flat_map(@registries, & &1.all())

  @doc "Find a tool module by its LLM-facing name across all registries."
  def get(name) do
    Enum.find(all(), fn tool -> tool.name() == name end)
  end

  @doc false
  def format_errors(%Ecto.Changeset{} = changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, _opts} -> msg end)
  end

  def format_errors(other), do: inspect(other)
end
