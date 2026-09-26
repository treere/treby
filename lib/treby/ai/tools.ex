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
  Required action for a tool (fail-closed atom or nil when unmapped).
  Delegates to `Treby.Authorization.action_for_tool/1`, which honors an
  optional `required_action/0` callback on the tool module.
  """
  def required_action(tool), do: Treby.Authorization.action_for_tool(tool)

  @doc """
  Required workspace role for a tool (deprecated).

  Kept for backward compatibility: returns `:admin` when the tool's required
  action is outside recruiter defaults, otherwise `:any`.
  Prefer `required_action/1` + `authorize/2`.
  """
  @deprecated "Use required_action/1 with authorize/2 instead"
  def required_role(tool) do
    if Code.ensure_loaded?(tool) and function_exported?(tool, :required_role, 0) do
      tool.required_role()
    else
      case required_action(tool) do
        nil ->
          :admin

        action ->
          if action in Treby.Authorization.preset_defaults("recruiter"), do: :any, else: :admin
      end
    end
  end

  @doc "True when the context belongs to a workspace admin."
  def admin?(ctx), do: ctx[:role] in ["admin", :admin]

  @doc "The membership actor to pass to contexts (normalized via Actor)."
  def actor(ctx), do: Treby.Authorization.Actor.from(ctx)

  @doc "The id of the membership actor, or nil."
  def actor_id(ctx) do
    case actor(ctx) do
      %{id: id} -> id
      _ -> nil
    end
  rescue
    _ -> nil
  end

  @doc """
  Filter a toolset by effective permissions, hiding denied tools from the model.

  Accepts a MapSet, a context map carrying `:permissions` / `:role`, or a
  legacy role string (preset defaults, no overrides).
  """
  def for_role(tools, role) when (is_list(tools) and is_binary(role)) or is_atom(role) do
    effective = Treby.Authorization.effective_permissions(role, %{})
    for_permissions(tools, effective)
  end

  def for_role(tools, %MapSet{} = effective) when is_list(tools) do
    for_permissions(tools, effective)
  end

  def for_role(tools, %{} = ctx) when is_list(tools) do
    for_permissions(tools, effective(ctx))
  end

  def for_permissions(tools, %MapSet{} = effective) when is_list(tools) do
    Enum.filter(tools, fn tool ->
      case required_action(tool) do
        nil -> false
        action -> Treby.Authorization.Policy.can?(effective, action)
      end
    end)
  end

  @doc "Effective permission set for a context (delegates to Actor)."
  def effective(%{permissions: %MapSet{} = effective}), do: effective

  def effective(%{} = ctx) do
    case Treby.Authorization.Actor.from(ctx) do
      %{permissions: %MapSet{} = perms} -> perms
      _ -> MapSet.new()
    end
  rescue
    _ -> MapSet.new()
  end

  def effective(_), do: MapSet.new()

  @doc "Return `:ok` when the context permissions satisfy the tool's required action."
  def authorize(tool, ctx) do
    case required_action(tool) do
      nil ->
        {:error, :unauthorized}

      action ->
        if Treby.Authorization.Policy.can?(Treby.Authorization.Actor.from(ctx), action),
          do: :ok,
          else: {:error, :unauthorized}
    end
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
    establish_ctx_tenant(ctx)

    with :ok <- authorize(tool, ctx),
         {:ok, valid} <- validate(tool, args) do
      tool.run(valid, ctx)
    end
  end

  # Agent processes may outlive the request that set the tenant; the ctx
  # tenant is authoritative for the tool call.
  defp establish_ctx_tenant(ctx) do
    case ctx[:tenant_id] || ctx["tenant_id"] do
      nil -> :ok
      tenant_id -> Treby.Repo.put_tenant_id(tenant_id)
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
