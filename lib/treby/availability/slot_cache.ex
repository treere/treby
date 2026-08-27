defmodule Treby.Availability.SlotCache do
  @moduledoc """
  Simple ETS-based cache for availability slot computations.
  Entries expire after 5 minutes.
  """

  @table :availability_slot_cache
  @ttl_seconds 300

  def init do
    :ets.new(@table, [:named_table, :set, :public])
  end

  def get(examiner_ids, date_range) do
    key = cache_key(examiner_ids, date_range)

    case :ets.lookup(@table, key) do
      [{^key, slots, inserted_at}] ->
        if System.system_time(:second) - inserted_at < @ttl_seconds do
          slots
        else
          :ets.delete(@table, key)
          nil
        end

      [] ->
        nil
    end
  end

  def put(examiner_ids, date_range, slots) do
    key = cache_key(examiner_ids, date_range)
    :ets.insert(@table, {key, slots, System.system_time(:second)})
  end

  def invalidate do
    :ets.delete_all_objects(@table)
  end

  defp cache_key(examiner_ids, date_range) do
    sorted_ids = Enum.sort(examiner_ids)
    {sorted_ids, date_range.from, date_range.to}
  end
end
