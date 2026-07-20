defmodule Treby.Availability do
  @moduledoc """
  Context for availability rules and slot computation.
  """

  import Ecto.Query
  alias Treby.Repo
  alias Treby.Availability.AvailabilityRule

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

    case Treby.Calendar.get_free_busy(user_id, time_min, time_max) do
      {:ok, periods} -> {:ok, periods}
      {:error, :not_connected} -> {:ok, []}
      {:error, reason} -> {:error, {:calendar_error, reason}}
    end
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
end
