defmodule Treby.Availability do
  @moduledoc """
  Context for availability rules and slot computation.
  """

  import Ecto.Query
  alias Treby.Repo
  alias Treby.Availability.AvailabilityRule
  alias Treby.Availability.ProviderCache
  alias Treby.Calendar.Providers.Treby, as: InternalCalendar

  @slot_duration_minutes 30

  def list_rules_for_user(user_id) do
    AvailabilityRule
    |> where([r], r.user_id == ^user_id)
    |> order_by([r], r.day_of_week)
    |> Repo.all()
  end

  def list_rules_for_user_on_days(user_id, days) do
    AvailabilityRule
    |> where([r], r.user_id == ^user_id and r.day_of_week in ^days)
    |> order_by([r], r.day_of_week)
    |> Repo.all()
  end

  def get_rule!(id), do: Repo.get!(AvailabilityRule, id)

  def get_rule_for_user_day(user_id, day_of_week) do
    AvailabilityRule
    |> where([r], r.user_id == ^user_id and r.day_of_week == ^day_of_week)
    |> Repo.one()
  end

  def create_rule(attrs) do
    %AvailabilityRule{}
    |> AvailabilityRule.changeset(attrs)
    |> Repo.insert()
  end

  def update_rule(%AvailabilityRule{} = rule, attrs) do
    rule
    |> AvailabilityRule.changeset(attrs)
    |> Repo.update()
  end

  def delete_rule(%AvailabilityRule{} = rule) do
    Repo.delete(rule)
  end

  def change_rule(%AvailabilityRule{} = rule, attrs \\ %{}) do
    AvailabilityRule.changeset(rule, attrs)
  end

  @doc """
  Compute available slots for a user over a date range.

  Returns a list of %{start: DateTime, end: DateTime} maps representing
  available 30-minute interview slots.

  ## Parameters
    - user_id: The interviewer's user ID
    - date_range: %{from: Date, to: Date} or a Date range
    - duration_minutes: Slot duration (default 30)
    - timezone: Timezone for the date range (default "UTC")
  """
  def compute_slots(
        user_id,
        date_range,
        duration_minutes \\ @slot_duration_minutes,
        timezone \\ "UTC"
      ) do
    dates = Date.range(date_range.from, date_range.to)
    days = Enum.map(dates, &Date.day_of_week/1)

    rules = list_rules_for_user_on_days(user_id, days)

    rules_by_day = Map.new(rules, &{&1.day_of_week, &1})

    case get_busy_periods(user_id, dates) do
      {:ok, busy_periods} ->
        dates
        |> Enum.flat_map(fn date ->
          day_of_week = Date.day_of_week(date)

          case Map.get(rules_by_day, day_of_week) do
            nil ->
              []

            rule ->
              generate_slots_for_day(date, rule, busy_periods, duration_minutes, timezone)
          end
        end)

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp get_busy_periods(user_id, dates) do
    first_date = Enum.min(dates)
    last_date = Enum.max(dates)

    time_min =
      first_date
      |> DateTime.new!(~T[00:00:00], "Etc/UTC")

    time_max =
      last_date
      |> Date.add(1)
      |> DateTime.new!(~T[00:00:00], "Etc/UTC")

    with {:ok, internal} <- InternalCalendar.fetch_busy(user_id, time_min, time_max),
         {:ok, external} <- fetch_external_busy(user_id, time_min, time_max) do
      {:ok, internal ++ external}
    end
  end

  defp fetch_external_busy(user_id, time_min, time_max) do
    user_id
    |> Treby.Calendar.list_connections_for_user()
    |> Enum.reduce_while({:ok, []}, fn conn, {:ok, acc} ->
      key = {conn.provider, conn.user_id, time_min, time_max}

      case ProviderCache.fetch(key, fn ->
             Treby.Calendar.fetch_provider_busy(conn, time_min, time_max)
           end) do
        {:ok, periods} -> {:cont, {:ok, acc ++ periods}}
        {:error, reason} -> {:halt, {:error, {:calendar_error, {conn.provider, reason}}}}
      end
    end)
  end

  defp generate_slots_for_day(date, rule, busy_periods, duration_minutes, _timezone) do
    tz = rule.timezone

    day_start = DateTime.new!(date, rule.start_time, tz)
    day_end = DateTime.new!(date, rule.end_time, tz)

    buffer_before = rule.buffer_before * 60
    buffer_after = rule.buffer_after * 60

    day_start
    |> Stream.unfold(fn current ->
      slot_end = DateTime.add(current, duration_minutes, :minute)

      if DateTime.compare(slot_end, day_end) != :gt do
        {current, slot_end}
      else
        nil
      end
    end)
    |> Enum.filter(fn slot_start ->
      slot_end = DateTime.add(slot_start, duration_minutes, :minute)
      buffered_start = DateTime.add(slot_start, -buffer_before, :second)
      buffered_end = DateTime.add(slot_end, buffer_after, :second)

      not overlaps_any?(buffered_start, buffered_end, busy_periods)
    end)
    |> Enum.map(fn slot_start ->
      %{
        start: slot_start,
        end: DateTime.add(slot_start, duration_minutes, :minute)
      }
    end)
  end

  defp overlaps_any?(start_dt, end_dt, periods) do
    Enum.any?(periods, fn period ->
      DateTime.compare(start_dt, period.end) == :lt and
        DateTime.compare(end_dt, period.start) == :gt
    end)
  end

  @doc """
  Compute overlapping available slots for multiple examiners.

  Returns a list of %{start: DateTime, end: DateTime, available_examiners: [user_id]} maps
  representing slots where at least `min_examiners` are simultaneously available.

  ## Parameters
    - examiner_ids: List of user IDs for eligible examiners
    - min_examiners: Minimum number of examiners that must be available
    - date_range: %{from: Date, to: Date}
    - duration_minutes: Slot duration (default 30)
    - timezone: Timezone for the date range (default "UTC")
  """
  def compute_overlapping_slots(
        examiner_ids,
        min_examiners,
        date_range,
        duration_minutes \\ @slot_duration_minutes,
        _timezone \\ "UTC"
      ) do
    do_compute_overlapping_slots(examiner_ids, min_examiners, date_range, duration_minutes)
  end

  defp do_compute_overlapping_slots(examiner_ids, min_examiners, date_range, duration_minutes) do
    dates = Date.range(date_range.from, date_range.to)
    days = Enum.map(dates, &Date.day_of_week/1)

    # Get rules for all examiners, keyed by {user_id, day_of_week}
    rules_map =
      examiner_ids
      |> Enum.flat_map(fn user_id ->
        rules = list_rules_for_user_on_days(user_id, days)
        Enum.map(rules, fn rule -> {{user_id, rule.day_of_week}, rule} end)
      end)
      |> Map.new()

    # Get busy periods for all examiners (internal + connected external providers)
    with {:ok, busy_map} <- build_busy_map(examiner_ids, dates) do
      # For each date, compute overlapping slots
      dates
      |> Enum.flat_map(fn date ->
        day_of_week = Date.day_of_week(date)

        # Get rules for this day for each examiner
        rules_for_day =
          examiner_ids
          |> Enum.map(fn user_id ->
            {user_id, Map.get(rules_map, {user_id, day_of_week})}
          end)

        # Find the intersection of availability windows
        # Only consider examiners that have a rule for this day
        available_examiners =
          rules_for_day
          |> Enum.filter(fn {_uid, rule} -> rule != nil end)
          |> Enum.map(fn {uid, _rule} -> uid end)

        if length(available_examiners) < min_examiners do
          []
        else
          # Find the common time window (latest start, earliest end) across all available examiners
          latest_start =
            rules_for_day
            |> Enum.filter(fn {_uid, rule} -> rule != nil end)
            |> Enum.map(fn {_uid, rule} -> rule.start_time end)
            |> Enum.max(Time)

          earliest_end =
            rules_for_day
            |> Enum.filter(fn {_uid, rule} -> rule != nil end)
            |> Enum.map(fn {_uid, rule} -> rule.end_time end)
            |> Enum.min(Time)

          # Use the timezone from the first available rule
          first_rule =
            rules_for_day
            |> Enum.find(fn {_uid, rule} -> rule != nil end)
            |> elem(1)

          tz = first_rule.timezone
          buffer_before = first_rule.buffer_before * 60
          buffer_after = first_rule.buffer_after * 60

          day_start = DateTime.new!(date, latest_start, tz)
          day_end = DateTime.new!(date, earliest_end, tz)

          # Generate candidate slots from the common window
          candidate_slots =
            day_start
            |> Stream.unfold(fn current ->
              slot_end = DateTime.add(current, duration_minutes, :minute)

              if DateTime.compare(slot_end, day_end) != :gt do
                {current, slot_end}
              else
                nil
              end
            end)
            |> Enum.to_list()

          # For each candidate slot, count how many examiners are free
          candidate_slots
          |> Enum.map(fn slot_start ->
            slot_end = DateTime.add(slot_start, duration_minutes, :minute)
            buffered_start = DateTime.add(slot_start, -buffer_before, :second)
            buffered_end = DateTime.add(slot_end, buffer_after, :second)

            free_examiners =
              available_examiners
              |> Enum.filter(fn user_id ->
                busy = Map.get(busy_map, user_id, [])
                not overlaps_any?(buffered_start, buffered_end, busy)
              end)

            {slot_start, slot_end, free_examiners}
          end)
          |> Enum.filter(fn {_start, _end, free} -> length(free) >= min_examiners end)
          |> Enum.map(fn {start, end_dt, free} ->
            %{start: start, end: end_dt, available_examiners: free}
          end)
        end
      end)
    end
  end

  defp build_busy_map(examiner_ids, dates) do
    Enum.reduce_while(examiner_ids, {:ok, %{}}, fn user_id, {:ok, acc} ->
      case get_busy_periods(user_id, dates) do
        {:ok, periods} -> {:cont, {:ok, Map.put(acc, user_id, periods)}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end
end
