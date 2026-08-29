defmodule Treby.Availability.ProviderCacheTest do
  use ExUnit.Case, async: false

  alias Treby.Availability.ProviderCache

  @global_name {:provider_busy_cache, ProviderCache}
  @table :provider_busy_cache

  test "returns cached value on subsequent calls" do
    key = {:test, :cache_hit, System.unique_integer([:positive])}

    {:ok, counter} = Agent.start_link(fn -> 0 end)

    fun = fn ->
      Agent.update(counter, &(&1 + 1))
      {:ok, :value}
    end

    assert {:ok, :value} = ProviderCache.fetch(key, fun)
    assert {:ok, :value} = ProviderCache.fetch(key, fun)

    assert Agent.get(counter, & &1) == 1
  end

  test "recomputes when the cached entry has expired" do
    key = {:test, :expired, System.unique_integer([:positive])}

    :ets.insert(@table, {key, "stale", 0})

    assert {:ok, "fresh"} = ProviderCache.fetch(key, fn -> {:ok, "fresh"} end)
    assert {:ok, "fresh"} = ProviderCache.fetch(key, fn -> {:ok, "fresh"} end)
  end

  test "error results are not cached and propagate" do
    key = {:test, :error, System.unique_integer([:positive])}

    {:ok, counter} = Agent.start_link(fn -> 0 end)

    fun = fn ->
      Agent.update(counter, &(&1 + 1))
      {:error, :boom}
    end

    assert {:error, :boom} = ProviderCache.fetch(key, fun)
    assert {:error, :boom} = ProviderCache.fetch(key, fun)

    assert Agent.get(counter, & &1) == 2
  end

  test "falls back to direct fetch when the cache owner is unavailable" do
    key = {:test, :loss, System.unique_integer([:positive])}

    :global.unregister_name(@global_name)

    try do
      assert {:ok, "direct"} = ProviderCache.fetch(key, fn -> {:ok, "direct"} end)
    after
      :global.register_name(@global_name, Process.whereis(ProviderCache))
    end
  end
end
