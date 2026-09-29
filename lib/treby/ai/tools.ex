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

  @max_summary_fields 8
  @max_value_chars 120

  @doc """
  Human-readable summary of a tool call for confirmation cards.

  Returns `%{title: binary, fields: [{label, value}]}`. Uses the tool's
  curated `summary/1` when implemented, otherwise a generic humanizer over
  the raw args. Never raises: falls back to the raw-args view on any error.
  """
  def describe(tool_name, args) when is_binary(tool_name) and is_map(args) do
    case get(tool_name) do
      nil ->
        fallback_summary(tool_name, args)

      tool ->
        if function_exported?(tool, :summary, 1) do
          try do
            normalize_summary(tool.summary(args), tool_name, args)
          rescue
            _ -> fallback_summary(tool_name, args)
          end
        else
          fallback_summary(tool_name, args)
        end
    end
  end

  def describe(tool_name, _args), do: %{title: humanize(tool_name), fields: []}

  @doc "True when the tool provides its own curated `summary/1`."
  def curated?(tool_name) when is_binary(tool_name) do
    case get(tool_name) do
      nil -> false
      tool -> function_exported?(tool, :summary, 1)
    end
  end

  defp normalize_summary(%{title: title, fields: fields}, tool_name, args)
       when is_binary(title) and is_list(fields) do
    rows =
      fields
      |> Enum.flat_map(fn
        {label, value} when is_binary(label) -> [{label, format_value(value)}]
        _ -> []
      end)
      |> Enum.reject(fn {_label, value} -> blank?(value) end)
      |> Enum.take(@max_summary_fields)

    if rows == [] do
      fallback_summary(tool_name, args)
    else
      %{title: title, fields: rows}
    end
  end

  defp normalize_summary(_, tool_name, args), do: fallback_summary(tool_name, args)

  defp fallback_summary(tool_name, args) do
    rows =
      args
      |> Enum.flat_map(fn
        {key, value} when is_binary(key) -> [{humanize(key), format_value(value)}]
        _ -> []
      end)
      |> Enum.reject(fn {_label, value} -> blank?(value) end)
      |> Enum.take(@max_summary_fields)

    %{title: humanize(tool_name), fields: rows}
  end

  defp blank?(nil), do: true
  defp blank?(""), do: true
  defp blank?([]), do: true
  defp blank?(map) when is_map(map) and map_size(map) == 0, do: true
  defp blank?(_), do: false

  defp humanize(key) do
    key
    |> String.replace_suffix("_ids", "")
    |> String.replace_suffix("_id", "")
    |> String.replace("_", " ")
    |> String.capitalize()
  end

  defp format_value(nil), do: nil
  defp format_value(""), do: nil
  defp format_value(value) when is_boolean(value), do: to_string(value)
  defp format_value(value) when is_number(value), do: to_string(value)

  defp format_value(value) when is_binary(value) do
    if String.length(value) > @max_value_chars do
      String.slice(value, 0, @max_value_chars) <> "…"
    else
      value
    end
  end

  defp format_value([]), do: nil

  defp format_value(values) when is_list(values) do
    case Enum.map(values, &format_scalar/1) do
      [] ->
        nil

      [first] ->
        truncate("1 item: #{first}", @max_value_chars)

      [first, second] when length(values) == 2 ->
        truncate("2 items: #{first}, #{second}", @max_value_chars)

      [first | _] ->
        truncate("#{length(values)} items: #{first}, …", @max_value_chars)
    end
  end

  defp format_value(%{} = map) when map_size(map) == 0, do: nil
  defp format_value(%{} = map), do: "#{map_size(map)} fields"

  defp format_value(other), do: truncate(inspect(other), @max_value_chars)

  defp format_scalar(value) when is_binary(value), do: truncate(value, 40)
  defp format_scalar(value) when is_number(value) or is_boolean(value), do: to_string(value)
  defp format_scalar(_), do: "…"

  defp truncate(text, max) when is_binary(text) do
    if String.length(text) > max, do: String.slice(text, 0, max) <> "…", else: text
  end

  @entity_types %{
    "create_job" => :job,
    "update_job" => :job,
    "delete_job" => :job,
    "create_candidate" => :candidate,
    "update_candidate" => :candidate,
    "delete_candidate" => :candidate,
    "merge_candidates" => :candidate,
    "bulk_delete_candidates" => :candidate,
    "import_candidates_csv" => :candidate,
    "create_application" => :application,
    "move_application" => :application,
    "set_application_reviewed" => :application,
    "bulk_move_stage" => :application,
    "bulk_review" => :application,
    "add_note" => :note,
    "update_note" => :note,
    "delete_note" => :note,
    "schedule_interview" => :interview,
    "cancel_interview" => :interview,
    "complete_interview" => :interview,
    "submit_scorecard" => :interview,
    "create_pipeline" => :pipeline,
    "update_pipeline" => :pipeline,
    "delete_pipeline" => :pipeline,
    "add_pipeline_stage" => :pipeline_stage,
    "update_pipeline_stage" => :pipeline_stage,
    "delete_pipeline_stage" => :pipeline_stage,
    "assign_stage_person" => :pipeline_stage,
    "unassign_stage_person" => :pipeline_stage,
    "send_message" => :message,
    "bulk_send_message" => :message,
    "schedule_message" => :message,
    "cancel_scheduled_message" => :message,
    "reschedule_scheduled_message" => :message,
    "retry_scheduled_message" => :message,
    "create_email_template" => :email_template,
    "update_email_template" => :email_template,
    "delete_email_template" => :email_template,
    "create_webhook" => :webhook,
    "update_webhook" => :webhook,
    "delete_webhook" => :webhook,
    "test_webhook" => :webhook,
    "create_custom_field" => :custom_field,
    "update_custom_field" => :custom_field,
    "delete_custom_field" => :custom_field,
    "create_scorecard_template" => :scorecard_template,
    "update_scorecard_template" => :scorecard_template,
    "delete_scorecard_template" => :scorecard_template,
    "create_availability_rule" => :availability_rule,
    "update_availability_rule" => :availability_rule,
    "delete_availability_rule" => :availability_rule,
    "create_calendar_event" => :calendar_event,
    "create_data_request" => :data_request,
    "cancel_data_request" => :data_request,
    "update_career_page" => :career_page,
    "add_member" => :member,
    "invite_member" => :member,
    "remove_member" => :member,
    "update_member_role" => :member,
    "delete_invite" => :invite,
    "update_settings" => :settings
  }

  @doc """
  Map a confirmed tool result to the affected entity for page refresh.

  Returns `%{type: atom, id: binary | nil}` or nil when the tool has no
  mappable entity. Bulk results carry no single id (`id: nil`).
  """
  def entity_of(tool_name, result) when is_binary(tool_name) and is_map(result) do
    case Map.fetch(@entity_types, tool_name) do
      {:ok, type} -> %{type: type, id: result["id"]}
      :error -> nil
    end
  end

  def entity_of(_, _), do: nil
end
