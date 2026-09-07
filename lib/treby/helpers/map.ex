defmodule Treby.Helpers.Map do
  @moduledoc """
  Shared map helpers used across contexts.
  """

  @doc """
  Converts all map keys to strings.

  ## Examples

      iex> Treby.Helpers.Map.stringify_keys(%{:a => 1, "b" => 2})
      %{"a" => 1, "b" => 2}
  """
  @spec stringify_keys(map()) :: map()
  def stringify_keys(attrs) when is_map(attrs) do
    Map.new(attrs, fn {key, value} -> {to_string(key), value} end)
  end
end
