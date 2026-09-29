defmodule TrebyWeb.AiRefresh do
  @moduledoc """
  Shared helpers for live page refresh after confirmed assistant tool runs.

  The assistant broadcasts `{:ai_entity_changed, entity}` (via the chat hook)
  to the host LiveView. Pages that display the entity refresh their assigns;
  pages that don't display it show a short flash notice naming the change.
  """

  use Gettext, backend: TrebyWeb.Gettext

  import Phoenix.LiveView, only: [put_flash: 3]

  @doc "Short human label for an entity type (e.g. `:job` -> \"job\")."
  def entity_label(%{type: type}) when is_atom(type) do
    type |> Atom.to_string() |> String.replace("_", " ")
  end

  def entity_label(_), do: "item"

  @doc """
  Flash a notice about an entity the page does not live-refresh.
  Silent for unknown payloads.
  """
  def put_entity_flash(socket, %{type: type} = entity) when is_atom(type) do
    put_flash(
      socket,
      :info,
      gettext("The assistant updated a %{entity}.", entity: entity_label(entity))
    )
  end

  def put_entity_flash(socket, _), do: socket
end
