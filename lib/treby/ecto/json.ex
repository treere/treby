defmodule Treby.Ecto.JSON do
  @moduledoc """
  Custom Ecto type for storing arbitrary JSON (maps or lists) in a jsonb column.
  """
  use Ecto.Type

  @impl true
  def type, do: :map

  @impl true
  def cast(value) when is_map(value), do: {:ok, value}
  def cast(value) when is_list(value), do: {:ok, value}
  def cast(_), do: :error

  @impl true
  def load(%{} = data), do: {:ok, data}
  def load(data) when is_list(data), do: {:ok, data}
  def load(_), do: :error

  @impl true
  def dump(%{} = data), do: {:ok, data}
  def dump(data) when is_list(data), do: {:ok, data}
  def dump(_), do: :error
end
