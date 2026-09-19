defmodule Treby.Availability do
  @moduledoc """
  Context for availability rules and slot computation.
  """

  import Ecto.Query
  import Ecto.Changeset
  alias Treby.Repo
  alias Treby.Accounts.User
  alias Treby.Tenants.Tenant
  alias Treby.Availability.AvailabilityRule
  alias Treby.Availability.ProviderCache
  alias Treby.Calendar.Providers.Treby, as: InternalCalendar

  @slot_duration_minutes 30

  defp normalize_dow(7), do: 0
  defp normalize_dow(dow) when dow in 0..6, do: dow
  defp normalize_dow(dow) when dow in 1..6, do: dow

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

  def list_company_rules(tenant_id) do
    AvailabilityRule
    |> where([r], r.tenant_id == ^tenant_id and r.scope == "company")
    |> order_by([r], r.day_of_week)
    |> Repo.all()
  end

  def list_user_rules(user_id) do
    AvailabilityRule
    |> where([r], r.user_id == ^user_id and r.scope == "user")
    |> order_by([r], r.day_of_week)
    |> Repo.all()
  end

  def resolve_rules_for_user(%User{} = user, %Tenant{} = tenant) do
    case list_user_rules(user.id) do
      [] ->
        case list_company_rules(tenant.id) do
          [] -> {[], "UTC"}
          company_rules -> {company_rules, tenant.timezone || "UTC"}
        end

      user_rules ->
        {user_rules, user.timezone || "UTC"}
    end
  end

  def resolve_rules_for_user(%User{} = user, nil) do
    case list_user_rules(user.id) do
      [] -> {[], "UTC"}
      user_rules -> {user_rules, user.timezone || "UTC"}
    end
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
  Seed the company default availability template for a tenant.

  Creates Monday–Friday rules with two windows: 09:00–13:00 and 14:00–18:00,
  interpreted in the company timezone.
  """
  def seed_company_default_rules(%Tenant{} = tenant) do
    for dow <- 1..5,
        {start_time, end_time} <- [{~T[09:00:00], ~T[13:00:00]}, {~T[14:00:00], ~T[18:00:00]}] do
      %AvailabilityRule{}
      |> AvailabilityRule.changeset(%{
        day_of_week: dow,
        start_time: start_time,
        end_time: end_time,
        scope: "company",
        tenant_id: tenant.id
      })
      |> Repo.insert!()
    end
  end

  @doc """
  Materialize a user's availability as a copy of the company template.

  Sets the user timezone to the company timezone when not already set, then copies
  the company rules into the user's own scope.
  """
  def seed_user_from_company(%User{} = user, %Tenant{} = tenant) do
    user = if blank?(user.timezone), do: set_user_timezone(user, tenant.timezone), else: user

    Enum.each(list_company_rules(tenant.id), fn rule ->
      %AvailabilityRule{}
      |> AvailabilityRule.changeset(%{
        day_of_week: rule.day_of_week,
        start_time: rule.start_time,
        end_time: rule.end_time,
        scope: "user",
        user_id: user.id,
        tenant_id: tenant.id
      })
      |> Repo.insert!()
    end)

    user
  end

  defp blank?(nil), do: true
  defp blank?(""), do: true
  defp blank?(_), do: false

  defp set_user_timezone(user, timezone) do
    user
    |> change(%{timezone: timezone})
    |> Repo.update!()
  end

  @doc """
  Compute available slots for a user over a date range.

  Returns a list of %{start: DateTime, end: DateTime} maps. Falls back to the
  company template when the user has no rules, and to an empty list when neither
  is configured. Returns {:error, reason} when busy-period lookup fails.
  """
  def compute_slots(
        user_id,
        date_range,
        duration_minutes \\ @slot_duration_minutes,
        _timezone \\ "UTC"
      ) do
    case Repo.get(User, user_id) do
      nil ->
        []

      user ->
        tenant = if user.tenant_id, do: Repo.get(Tenant, user.tenant_id), else: nil
        {rules, tz} = resolve_rules_for_user(user, tenant)
        dates = Date.range(date_range.from, date_range.to)
        rules_by_day = Enum.group_by(rules, & &1.day_of_week)

        case get_busy_periods(user_id, dates) do
          {:ok, busy_periods} ->
            dates
            |> Enum.flat_map(fn date ->
              dow = Date.day_of_week(date) |> normalize_dow()

              generate_slots_for_day(
                date,
                Map.get(rules_by_day, dow, []),
                busy_periods,
                duration_minutes,
                tz
              )
            end)

          {:error, reason} ->
            {:error, reason}
        end
    end
  end

  @doc """
  Compute overlapping available slots for multiple examiners.

  Returns a list of %{start: DateTime, end: DateTime, available_examiners: [user_id]}
  maps. Returns {:error, reason} when busy-period lookup fails.
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

    examiners =
      Enum.map(examiner_ids, fn id ->
        user = Repo.get(User, id)
        tenant = if user && user.tenant_id, do: Repo.get(Tenant, user.tenant_id), else: nil
        {user, resolve_rules_for_user(user, tenant)}
      end)

    valid = Enum.filter(examiners, fn {user, _} -> not is_nil(user) end)

    case build_busy_map(examiner_ids, dates) do
      {:ok, busy_map} ->
        dates
        |> Enum.flat_map(fn date ->
          start_map =
            Enum.reduce(valid, %{}, fn {user, {rules, tz}}, acc ->
              dow = Date.day_of_week(date) |> normalize_dow()
              rules_by_day = Enum.group_by(rules, & &1.day_of_week)
              windows = Map.get(rules_by_day, dow, [])
              busy = Map.get(busy_map, user.id, [])
              free = free_slot_starts(date, windows, busy, duration_minutes, tz)

              Enum.reduce(free, acc, fn start_dt, acc2 ->
                Map.update(acc2, start_dt, [user.id], &[user.id | &1])
              end)
            end)

          start_map
          |> Enum.filter(fn {_start, ids} -> length(ids) >= min_examiners end)
          |> Enum.map(fn {start_dt, ids} ->
            %{
              start: start_dt,
              end: DateTime.add(start_dt, duration_minutes, :minute),
              available_examiners: ids
            }
          end)
        end)

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp window_slots(date, start_time, end_time, duration_minutes, tz) do
    day_start = DateTime.new!(date, start_time, tz)
    day_end = DateTime.new!(date, end_time, tz)

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
  end

  defp generate_slots_for_day(date, rules, busy_periods, duration_minutes, tz)
       when is_list(rules) do
    rules
    |> Enum.flat_map(fn rule ->
      window_slots(date, rule.start_time, rule.end_time, duration_minutes, tz)
    end)
    |> Enum.filter(fn slot_start ->
      slot_end = DateTime.add(slot_start, duration_minutes, :minute)
      not overlaps_any?(slot_start, slot_end, busy_periods)
    end)
    |> Enum.map(fn slot_start ->
      %{start: slot_start, end: DateTime.add(slot_start, duration_minutes, :minute)}
    end)
    |> Enum.sort_by(& &1.start)
    |> Enum.dedup_by(& &1.start)
  end

  defp free_slot_starts(date, rules, busy_periods, duration_minutes, tz) when is_list(rules) do
    rules
    |> Enum.flat_map(fn rule ->
      window_slots(date, rule.start_time, rule.end_time, duration_minutes, tz)
    end)
    |> Enum.filter(fn slot_start ->
      slot_end = DateTime.add(slot_start, duration_minutes, :minute)
      not overlaps_any?(slot_start, slot_end, busy_periods)
    end)
    |> Enum.dedup()
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

  defp overlaps_any?(start_dt, end_dt, periods) do
    Enum.any?(periods, fn period ->
      DateTime.compare(start_dt, period.end) == :lt and
        DateTime.compare(end_dt, period.start) == :gt
    end)
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
