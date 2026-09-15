defmodule Treby.AI.Context do
  @moduledoc """
  Builds the server-side context handed to the AI agent.

  Everything here comes from `socket.assigns` (already authorized by the
  membership hooks). Client payloads are never trusted for any of these
  fields — the LiveView sends only the message text.
  """

  @sensitive_keys ~w(
    current_user current_tenant current_membership available_tenants
    form flash streams __changed__ socket ai_session_token
  )a

  @doc """
  Builds the agent context map.

  Accepts a LiveView socket or a map with `:assigns` (and optionally `:view`).
  Returns a map with `:tenant_id`, `:user`, `:user_id`, `:role`, `:page`,
  `:url`, `:params`, `:assigns_snapshot`, `:form_schema`, `:session_token`
  and `:system_prompt`.
  """
  def build(source, _history \\ []) do
    assigns = Map.get(source, :assigns) || source
    view = Map.get(source, :view) || assigns[:current_view]
    user = assigns[:current_user]
    tenant = assigns[:current_tenant]
    membership = assigns[:current_membership]

    ctx = %{
      tenant_id: tenant && tenant.id,
      user: user,
      user_id: user && user.id,
      role: membership && membership.role,
      page: inspect(view),
      url: assigns[:current_path],
      params: assigns[:current_params] || %{},
      assigns_snapshot: snapshot(assigns),
      form_schema: form_schema(assigns),
      form_assign_key: form_assign_key(assigns),
      session_token: assigns[:ai_session_token]
    }

    Map.put(ctx, :system_prompt, system_prompt(ctx))
  end

  defp snapshot(assigns) do
    assigns
    |> Enum.reject(fn {key, _value} -> key in @sensitive_keys end)
    |> Enum.filter(fn {key, _value} ->
      is_atom(key) and not String.starts_with?(to_string(key), "_")
    end)
    |> Enum.flat_map(fn {key, value} ->
      case scalar(value) do
        {:ok, v} -> [{to_string(key), v}]
        :error -> []
      end
    end)
    |> Map.new()
  end

  defp scalar(v) when is_binary(v) or is_number(v) or is_boolean(v) or is_nil(v), do: {:ok, v}
  defp scalar(v) when is_atom(v), do: {:ok, to_string(v)}
  defp scalar(v) when is_list(v), do: if(Enum.all?(v, &scalar_ok?/1), do: {:ok, v}, else: :error)
  defp scalar(_), do: :error

  defp scalar_ok?(v), do: match?({:ok, _}, scalar(v))

  defp form_schema(assigns) when is_map(assigns) do
    case form_from(assigns[:form]) do
      nil -> Enum.find_value(assigns, fn {_key, value} -> form_from(value) end)
      schema -> schema
    end
  end

  defp form_schema(_), do: nil

  defp form_assign_key(assigns) when is_map(assigns) do
    if form_from(assigns[:form]) != nil do
      :form
    else
      Enum.find_value(assigns, fn {key, value} -> if form_from(value), do: key end)
    end
  end

  defp form_assign_key(_), do: nil

  defp form_from(%Ecto.Changeset{} = changeset), do: changeset_schema(changeset)

  defp form_from(%Phoenix.HTML.Form{source: %Ecto.Changeset{} = changeset}),
    do: changeset_schema(changeset)

  defp form_from(_), do: nil

  @internal_form_fields ~w(id tenant_id inserted_at updated_at created_at __meta__)a

  defp changeset_schema(changeset) do
    structure = Map.from_struct(changeset)
    types = Map.get(structure, :types, %{})
    required = Map.get(structure, :required, [])

    fields =
      types
      |> Enum.reject(fn {field, type} ->
        field in @internal_form_fields or match?({:assoc, _}, type)
      end)
      |> Enum.map(fn {field, type} ->
        %{
          "name" => to_string(field),
          "type" => inspect(type),
          "required" => field in required,
          "value" => value_for(changeset, field)
        }
      end)

    %{"fields" => fields}
  end

  defp value_for(changeset, field) do
    case Ecto.Changeset.get_field(changeset, field) do
      nil -> ""
      value -> value
    end
  end

  defp system_prompt(ctx) do
    """
    You are Treby's internal assistant for a hiring team.
    You help the user manage jobs, understand the platform, and co-edit forms.

    Current user: #{ctx.user && ctx.user.name} (#{ctx.user && ctx.user.email}), role: #{ctx.role}.
    Current workspace: #{ctx.tenant_id}. Always operate on this workspace; never
    ask for or accept a tenant id from the conversation.
    Current page: #{ctx.page} (#{ctx.url || "unknown"}).
    #{form_section(ctx.form_schema)}
    Use the provided tools when an action is needed. Read tools run immediately;
    any tool that writes requires the user's explicit per-item confirmation and
    is never executed by you directly. Keep replies concise and in markdown.
    """
  end

  defp form_section(nil), do: ""

  defp form_section(%{"fields" => fields}) do
    lines =
      Enum.map_join(fields, "\n", fn field ->
        value = field["value"]
        value_note = if value == "" or is_nil(value), do: "", else: ": #{inspect(value)}"

        "- #{field["name"]} (#{field["type"]})#{if field["required"], do: " *required*"}\n  current value: #{value_note}"
      end)

    "Form being edited (fields available to propose_form_fill):\n#{lines}"
  end
end
