defmodule Treby.Availability.ProviderCache do
  @moduledoc """
  Distributed in-cluster cache for external provider responses.

  A single GenServer per cluster owns an ETS table registered via `:global`.
  Standby instances on other nodes monitor the owner and take over on failover.
  The cache is purely an optimization: if it is unavailable or the owner is
  unreachable, callers fall back to fetching directly from the provider.

  Cached values are computed in the caller's process (so provider request
  stubs such as `Req.Test` continue to work) and stored via a cast.
  """

  use GenServer

  @table :provider_busy_cache
  @global_name {:provider_busy_cache, __MODULE__}
  @default_ttl_seconds 300

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @doc """
  Returns `{:ok, value}` from the cache when present and fresh; otherwise
  invokes `fun`, stores the successful result, and returns it.
  """
  def fetch(key, fun) do
    case :global.whereis_name(@global_name) do
      :undefined ->
        fun.()

      owner ->
        case safe_call(owner, {:get, key}) do
          {:ok, value} ->
            {:ok, value}

          :miss ->
            case fun.() do
              {:ok, value} = ok ->
                safe_cast(owner, {:put, key, value})
                ok

              other ->
                other
            end
        end
    end
  end

  @doc "Empties the cache."
  def invalidate do
    case :global.whereis_name(@global_name) do
      :undefined -> :ok
      owner -> safe_cast(owner, :invalidate)
    end
  end

  @impl true
  def init(:ok) do
    case :global.register_name(@global_name, self()) do
      :yes ->
        create_table()
        {:ok, %{monitor: nil}}

      :no ->
        {:ok, %{monitor: monitor_owner()}}
    end
  end

  @impl true
  def handle_call({:get, key}, _from, state) do
    cutoff = System.system_time(:second) - ttl_seconds()

    reply =
      case :ets.lookup(@table, key) do
        [{^key, value, inserted_at}] when inserted_at > cutoff ->
          {:ok, value}

        _ ->
          :miss
      end

    {:reply, reply, state}
  end

  @impl true
  def handle_cast({:put, key, value}, state) do
    :ets.insert(@table, {key, value, System.system_time(:second)})
    {:noreply, state}
  end

  def handle_cast(:invalidate, state) do
    :ets.delete_all_objects(@table)
    {:noreply, state}
  end

  @impl true
  def handle_info({:DOWN, ref, :process, _pid, _reason}, %{monitor: ref} = _state) do
    case :global.register_name(@global_name, self()) do
      :yes ->
        create_table()
        {:noreply, %{monitor: nil}}

      :no ->
        {:noreply, %{monitor: monitor_owner()}}
    end
  end

  def handle_info(_msg, state), do: {:noreply, state}

  defp create_table do
    :ets.new(@table, [:named_table, :set, :public, read_concurrency: true])
  end

  defp ttl_seconds do
    Application.get_env(:treby, :provider_cache_ttl_seconds) || @default_ttl_seconds
  end

  defp monitor_owner do
    case :global.whereis_name(@global_name) do
      :undefined -> nil
      pid -> Process.monitor(pid)
    end
  end

  defp safe_call(pid, msg) do
    GenServer.call(pid, msg, 2000)
  catch
    :exit, _ -> :miss
  end

  defp safe_cast(pid, msg) do
    GenServer.cast(pid, msg)
  catch
    :exit, _ -> :ok
  end
end
