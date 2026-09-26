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

  @doc """
  Required workspace role for a tool: `:admin` when the tool exports
  `required_role/0` returning `:admin`, otherwise `:any`.
  """
  def required_role(tool) do
    if Code.ensure_loaded?(tool) and function_exported?(tool, :required_role, 0) do
      tool.required_role()
    else
      :any
    end
  end

  @doc "True when the context belongs to a workspace admin."
  def admin?(ctx), do: ctx[:role] in ["admin", :admin]

  @doc "The membership actor to pass to contexts (falls back to the raw user)."
  def actor(ctx), do: ctx[:actor] || ctx[:user]

  @doc "The id of the membership actor, or nil."
  def actor_id(ctx) do
    case actor(ctx) do
      nil -> nil
      actor -> actor.id
    end
  end

  @doc "Filter a toolset by role, hiding admin-only tools from non-admins."
  def for_role(tools, role) when is_list(tools) do
    admin? = role in ["admin", :admin]
    Enum.filter(tools, fn tool -> admin? or required_role(tool) == :any end)
  end

  @doc "Return `:ok` when the context role satisfies the tool's requirement."
  def authorize(tool, ctx) do
    if required_role(tool) == :any or admin?(ctx), do: :ok, else: {:error, :unauthorized}
  end

  @doc """
  Validate decoded tool arguments against the tool's JSON schema using Zoi.

  The JSON schema is the single source of truth (also handed to the model), so
  every tool gets uniform input validation without duplicating schemas. Unknown
  keys are tolerated; type/required/enum violations are returned as an error the
  model can correct. Fails open if the schema cannot be decoded by Zoi.
  """
  def validate(tool, args) when is_map(args) do
    schema = Zoi.JSONSchema.decode(tool.schema())

    case Zoi.parse(schema, args) do
      {:ok, parsed} -> {:ok, parsed}
      {:error, errors} -> {:error, format_zoi_errors(errors)}
    end
  rescue
    _ -> {:ok, args}
  end

  def validate(_tool, _args), do: {:error, "arguments must be an object"}

  @doc """
  Single choke point: authorize by role, validate args against the tool schema,
  then delegate to the tool. Every tool call (read or confirmed write) goes
  through here so role and input checks are uniform.
  """
  def run(tool, args, ctx) do
    with :ok <- authorize(tool, ctx),
         {:ok, valid} <- validate(tool, args) do
      tool.run(valid, ctx)
    end
  end

  defp format_zoi_errors(errors) do
    Enum.map_join(errors, "; ", fn error ->
      path = Enum.join(error.path, ".")
      if path == "", do: error.message, else: "#{path} #{error.message}"
    end)
  end

  @doc false
  def format_errors(%Ecto.Changeset{} = changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, _opts} -> msg end)
  end

  def format_errors(other), do: inspect(other)
end
