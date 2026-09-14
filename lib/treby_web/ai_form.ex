defmodule TrebyWeb.AIForm do
  @moduledoc """
  Server-side helpers for applying assistant-proposed form values into the
  current page's form without touching the DOM from JavaScript.
  """

  @doc """
  Merge proposed `values` (field name -> value) into the LiveView's form held
  under `assign_key` (e.g. `:form`, `:edit_form`) and reassign it. No-op when
  there is no matching form or the field is unknown, so it is safe to call from
  any page.
  """
  def apply_values(socket, assign_key, values) when is_atom(assign_key) do
    case Map.get(socket.assigns, assign_key) do
      %Phoenix.HTML.Form{source: %Ecto.Changeset{} = changeset} ->
        changes =
          changeset.data
          |> Map.keys()
          |> Enum.filter(&Map.has_key?(values, to_string(&1)))
          |> Enum.into(%{}, &{&1, Map.get(values, to_string(&1))})

        updated = changeset |> Ecto.Changeset.change(changes) |> Phoenix.Component.to_form()
        %{socket | assigns: Map.put(socket.assigns, assign_key, updated)}

      _ ->
        socket
    end
  end

  def apply_values(socket, _assign_key, _values), do: socket
end
