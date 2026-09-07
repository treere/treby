defmodule TrebyWeb.LiveAudit do
  @moduledoc """
  Builds audit attrs (request IP and user-agent) from a LiveView socket.

  Best-effort: unavailable values become `nil`, which the audit schema
  accepts. Pass the result as `audit:` opt to context functions such as
  `Pipeline.move_application/3`.
  """

  @doc """
  Returns `%{ip: ..., user_agent: ...}` for the socket, merged with `extra`.
  """
  @spec attrs_from_socket(Phoenix.LiveView.Socket.t(), map()) :: map()
  def attrs_from_socket(socket, extra \\ %{}) do
    base = %{ip: peer_ip(socket), user_agent: user_agent(socket)}
    Map.merge(base, Enum.into(extra, %{}))
  end

  defp peer_ip(socket) do
    case Phoenix.LiveView.get_connect_info(socket, :peer_data) do
      %{address: address} when is_tuple(address) ->
        case :inet.ntoa(address) do
          {:error, _} -> nil
          ip -> to_string(ip)
        end

      _ ->
        nil
    end
  rescue
    _ -> nil
  end

  defp user_agent(socket) do
    Phoenix.LiveView.get_connect_info(socket, :user_agent)
  rescue
    _ -> nil
  end
end
