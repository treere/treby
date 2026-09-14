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
  defp scalar(v) when is_list(v), do: if(Enum.all?(v, &scalar/1), do: {:ok, v}, else: :error)
  defp scalar(_), do: :error

  defp form_schema(assigns) when is_map(assigns) do
    Enum.find_value(assigns, fn {_key, value} -> form_from(value) end)
  end

  defp form_schema(_), do: nil

  defp form_from(%Ecto.Changeset{} = changeset), do: changeset_schema(changeset)

  defp form_from(%Phoenix.HTML.Form{source: %Ecto.Changeset{} = changeset}),
    do: changeset_schema(changeset)

  defp form_from(_), do: nil

  defp changeset_schema(changeset) do
    structure = Map.from_struct(changeset)
    types = Map.get(structure, :types, %{})
    required = Map.get(structure, :required, [])
    fields = Map.keys(types)

    %{
      "fields" =>
        Enum.map(fields, fn field ->
          %{
            "name" => to_string(field),
            "type" => inspect(Map.get(types, field)),
            "required" => field in required
          }
        end)
    }
  end

  defp system_prompt(ctx) do
    """
    You are Treby's internal assistant for a hiring team.
    You help the user manage jobs, understand the platform, and co-edit forms.

    Current user: #{ctx.user && ctx.user.name} (#{ctx.user && ctx.user.email}), role: #{ctx.role}.
    Current workspace: #{ctx.tenant_id}. Always operate on this workspace; never
    ask for or accept a tenant id from the conversation.
    Current page: #{ctx.page} (#{ctx.url || "unknown"}).

    Use the provided tools when an action is needed. Read tools run immediately;
    any tool that writes requires the user's explicit per-item confirmation and
    is never executed by you directly. Keep replies concise and in markdown.
    """
  end
end
