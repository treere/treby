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
    {assign_key, values} 
    |> IO.inspect(label: "FORM")
    case Map.get(socket.assigns, assign_key) do
      %Phoenix.HTML.Form{source: %Ecto.Changeset{} = changeset} ->
        merged =
          Enum.reduce(values, changeset, fn {key, value}, acc ->
            field = field_atom(key)

            if field != nil and Map.has_key?(acc.data, field) do
              Ecto.Changeset.put_change(acc, field, value)
            else
              acc
            end
          end)

        IO.inspect("DONE")
        updated = Phoenix.Component.to_form(merged)
        {updated, values}
        |> IO.inspect()


        %{socket | assigns: Map.put(socket.assigns, assign_key, updated)}

      _ ->
        IO.inspect("FAIL")
        socket
    end
  end

  def apply_values(socket, _assign_key, _values), do: socket

  defp field_atom(key) when is_atom(key), do: key

  defp field_atom(key) when is_binary(key) do
    try do
      String.to_existing_atom(key)
    rescue
      ArgumentError -> nil
    end
  end

  defp field_atom(_), do: nil
end
