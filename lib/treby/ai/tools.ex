defmodule Treby.AI.Tools do
  @moduledoc """
  Registry + shared helpers for the hand-written AI tools.

  Tools are plain modules exposing `name/0`, `description/0`, `schema/0`,
  `destructive?/0` and `run/2`. No behaviour, no compile-time discovery.
  """

  alias Treby.AI.Tools.{
    CreateJob,
    DeleteJob,
    ExplainPage,
    ListJobs,
    ProposeFormFill,
    UpdateJob
  }

  @tools [ListJobs, CreateJob, UpdateJob, DeleteJob, ExplainPage, ProposeFormFill]

  @doc "All registered tool modules."
  def all, do: @tools

  @doc "Find a tool module by its LLM-facing name."
  def get(name) do
    Enum.find(@tools, fn tool -> tool.name() == name end)
  end

  @doc false
  def format_errors(%Ecto.Changeset{} = changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, _opts} -> msg end)
  end

  def format_errors(other), do: inspect(other)
end
