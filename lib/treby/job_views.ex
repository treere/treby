defmodule Treby.JobViews do
  @moduledoc """
  Job view tracking and analytics.
  """

  import Ecto.Query, warn: false
  alias Treby.Repo
  alias Treby.JobViews.JobView
  alias Treby.Jobs.Job

  @dedup_minutes_default 60
  @bot_regex ~r/bot|crawl|spider|slurp|mediapartners/i

  # -------------------------------------------------------------------
  # Public helpers
  # -------------------------------------------------------------------

  @doc """
  Returns true if the given User-Agent matches known bot patterns.
  """
  def bot?(nil), do: false
  def bot?(""), do: false

  def bot?(user_agent) when is_binary(user_agent) do
    Regex.match?(@bot_regex, user_agent)
  end

  @doc """
  Builds an anonymous session hash from IP + User-Agent + daily salt.
  Never persists the raw IP.
  """
  def session_hash(remote_ip, user_agent, date \\ Date.utc_today()) do
    salt = Date.to_iso8601(date)
    data = "#{remote_ip || "unknown"}|#{user_agent || "unknown"}|#{salt}"
    :crypto.hash(:sha256, data) |> Base.encode16(case: :lower) |> binary_part(0, 32)
  end

  @doc """
  Extracts a source label preferring utm_source, then referer domain, else "Direct".
  """
  def extract_source(utm_source, referer) do
    cond do
      is_binary(utm_source) and String.trim(utm_source) != "" -> String.trim(utm_source)
      is_binary(referer) and String.trim(referer) != "" -> extract_domain(referer)
      true -> "Direct"
    end
  end

  defp extract_domain(url) when is_binary(url) do
    case URI.parse(url) do
      %URI{host: host} when is_binary(host) and host != "" -> host
      _ -> url |> String.slice(0, 100)
    end
  end

  defp dedup_minutes do
    Application.get_env(:treby, :job_view_dedup_minutes, @dedup_minutes_default)
  end

  # -------------------------------------------------------------------
  # Tracking
  # -------------------------------------------------------------------

  @doc """
  Records a view for a job if eligible.

  Expected attrs:
    - :job_id (required)
    - :tenant_id (required)
    - :session_hash (required)
    - :viewed_at (optional, defaults to now)
    - :referer (optional, domain or URL — truncated)
    - :utm_source (optional)
    - :user_agent (optional, truncated to 255)

  Returns `{:ok, %JobView{}}` or `{:skip, reason}` where reason is
  `:closed`, `:bot`, `:deduplicated`, `:job_not_found`, `:tenant_mismatch`.

  Does not raise — caller should wrap in try/rescue if needed.
  """
  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  def track_view(attrs) when is_map(attrs) do
    job_id = attrs[:job_id] || attrs["job_id"]
    tenant_id = attrs[:tenant_id] || attrs["tenant_id"]
    session_hash = attrs[:session_hash] || attrs["session_hash"]
    user_agent = attrs[:user_agent] || attrs["user_agent"]
    referer = attrs[:referer] || attrs["referer"]
    utm_source = attrs[:utm_source] || attrs["utm_source"]

    viewed_at =
      attrs[:viewed_at] || attrs["viewed_at"] || DateTime.utc_now() |> DateTime.truncate(:second)

    cond do
      is_nil(job_id) or is_nil(tenant_id) or is_nil(session_hash) ->
        {:skip, :missing_params}

      bot?(user_agent) ->
        {:skip, :bot}

      true ->
        case Repo.get(Job, job_id) do
          nil ->
            {:skip, :job_not_found}

          %Job{tenant_id: ^tenant_id, status: "closed"} ->
            {:skip, :closed}

          %Job{tenant_id: ^tenant_id} = _job ->
            dedup_check_and_insert(%{
              job_id: job_id,
              tenant_id: tenant_id,
              session_hash: session_hash,
              viewed_at: viewed_at,
              referer: truncate(referer, 255),
              utm_source: truncate(utm_source, 100),
              user_agent: truncate(user_agent, 255)
            })

          %Job{} ->
            {:skip, :tenant_mismatch}
        end
    end
  end

  defp truncate(nil, _), do: nil

  defp truncate(val, max) when is_binary(val) do
    str =
      if String.contains?(val, "://") do
        extract_domain(val)
      else
        val
      end

    if String.length(str) > max, do: String.slice(str, 0, max), else: str
  end

  defp dedup_check_and_insert(attrs) do
    cutoff = DateTime.add(attrs.viewed_at, -dedup_minutes() * 60, :second)

    exists? =
      Repo.exists?(
        from v in JobView,
          where:
            v.job_id == ^attrs.job_id and v.session_hash == ^attrs.session_hash and
              v.viewed_at > ^cutoff
      )

    if exists? do
      {:skip, :deduplicated}
    else
      %JobView{}
      |> JobView.changeset(attrs)
      |> Repo.insert()
      |> case do
        {:ok, view} -> {:ok, view}
        {:error, changeset} -> {:error, changeset}
      end
    end
  end

  # -------------------------------------------------------------------
  # Aggregations
  # -------------------------------------------------------------------

  @doc """
  Returns summary metrics for a job. Verifies tenant ownership.
  Returns `{:ok, map}` or `{:error, :not_found}`.
  """
  def get_summary(tenant_id, job_id) do
    case verify_job_tenant(tenant_id, job_id) do
      {:error, _} = err -> err
      {:ok, _job} -> {:ok, build_summary(tenant_id, job_id)}
    end
  end

  @doc """
  Same as `get_summary/2` but returns the map directly (raises if job not found for tenant).
  Useful for LiveViews that already verified ownership.
  """
  def get_summary!(tenant_id, job_id) do
    case get_summary(tenant_id, job_id) do
      {:ok, summary} -> summary
      {:error, :not_found} -> raise Ecto.NoResultsError, queryable: JobView
    end
  end

  defp build_summary(tenant_id, job_id) do
    now = DateTime.utc_now()

    total_views =
      Repo.aggregate(
        from(v in JobView, where: v.tenant_id == ^tenant_id and v.job_id == ^job_id),
        :count
      )

    unique_views =
      Repo.one(
        from v in JobView,
          where: v.tenant_id == ^tenant_id and v.job_id == ^job_id,
          select: count(v.session_hash, :distinct)
      ) || 0

    views_last_7 = count_since(tenant_id, job_id, DateTime.add(now, -7 * 24 * 3600, :second))
    views_last_30 = count_since(tenant_id, job_id, DateTime.add(now, -30 * 24 * 3600, :second))
    views_last_90 = count_since(tenant_id, job_id, DateTime.add(now, -90 * 24 * 3600, :second))

    avg_daily = calc_avg_daily(tenant_id, job_id, total_views)

    %{
      total_views: total_views,
      unique_views: unique_views,
      views_last_7_days: views_last_7,
      views_last_30_days: views_last_30,
      views_last_90_days: views_last_90,
      avg_daily_views: avg_daily
    }
  end

  defp count_since(tenant_id, job_id, cutoff) do
    Repo.aggregate(
      from(v in JobView,
        where: v.tenant_id == ^tenant_id and v.job_id == ^job_id and v.viewed_at >= ^cutoff
      ),
      :count
    )
  end

  defp calc_avg_daily(_tenant_id, _job_id, 0), do: 0.0

  defp calc_avg_daily(tenant_id, job_id, total_views) do
    first =
      Repo.one(
        from v in JobView,
          where: v.tenant_id == ^tenant_id and v.job_id == ^job_id,
          order_by: [asc: v.viewed_at],
          limit: 1,
          select: v.viewed_at
      )

    case first do
      nil ->
        0.0

      dt ->
        days =
          Date.diff(Date.utc_today(), DateTime.to_date(dt)) + 1

        days = max(days, 1)
        Float.round(total_views / days, 1)
    end
  end

  @doc """
  Daily breakdown for last `days` days (default 30). Returns list of
  `%{date: Date.t(), count: integer}` ordered ascending, filling gaps with 0.
  Verifies tenant ownership.
  """
  def daily_breakdown(tenant_id, job_id, days \\ 30) do
    case verify_job_tenant(tenant_id, job_id) do
      {:error, _} = err -> err
      {:ok, _} -> {:ok, do_daily_breakdown(tenant_id, job_id, days)}
    end
  end

  defp do_daily_breakdown(tenant_id, job_id, days) do
    today = Date.utc_today()
    start_date = Date.add(today, -(days - 1))
    start_dt = DateTime.new!(start_date, ~T[00:00:00], "Etc/UTC")

    rows =
      Repo.all(
        from v in JobView,
          where: v.tenant_id == ^tenant_id and v.job_id == ^job_id and v.viewed_at >= ^start_dt,
          group_by: fragment("date_trunc('day', ?)", v.viewed_at),
          select: {fragment("date_trunc('day', ?)", v.viewed_at), count(v.id)}
      )

    # rows: [{~U[...], count}]
    map =
      Map.new(rows, fn {dt, cnt} ->
        date =
          case dt do
            %DateTime{} -> DateTime.to_date(dt)
            %NaiveDateTime{} -> NaiveDateTime.to_date(dt)
            _ -> nil
          end

        {date, cnt}
      end)

    Enum.map(0..(days - 1), fn offset ->
      date = Date.add(start_date, offset)
      %{date: date, count: Map.get(map, date, 0)}
    end)
  end

  @doc """
  Monthly breakdown for last `months` months (default 12). Returns list of
  `%{month: Date.t() (first day of month), count: integer}` ordered ascending.
  """
  def monthly_breakdown(tenant_id, job_id, months \\ 12) do
    case verify_job_tenant(tenant_id, job_id) do
      {:error, _} = err -> err
      {:ok, _} -> {:ok, do_monthly_breakdown(tenant_id, job_id, months)}
    end
  end

  defp do_monthly_breakdown(tenant_id, job_id, months) do
    today = Date.utc_today()
    # Generate months list first, then query
    months_list = for i <- (months - 1)..0//-1, do: shift_month(today, -i)

    start_dt = DateTime.new!(hd(months_list), ~T[00:00:00], "Etc/UTC")

    rows =
      Repo.all(
        from v in JobView,
          where: v.tenant_id == ^tenant_id and v.job_id == ^job_id and v.viewed_at >= ^start_dt,
          group_by: fragment("date_trunc('month', ?)", v.viewed_at),
          select: {fragment("date_trunc('month', ?)", v.viewed_at), count(v.id)}
      )

    map =
      Map.new(rows, fn {dt, cnt} ->
        date =
          case dt do
            %DateTime{} -> DateTime.to_date(dt) |> then(&%{&1 | day: 1})
            %NaiveDateTime{} -> NaiveDateTime.to_date(dt) |> then(&%{&1 | day: 1})
            _ -> nil
          end

        {date, cnt}
      end)

    Enum.map(months_list, fn month ->
      %{month: month, count: Map.get(map, month, 0)}
    end)
  end

  defp shift_month(date, offset) do
    # offset can be negative; move by months
    year = date.year
    month = date.month
    total_months = year * 12 + (month - 1) + offset
    new_year = div(total_months, 12)
    new_month = rem(total_months, 12) + 1
    %Date{year: new_year, month: new_month, day: 1}
  end

  @doc """
  Source breakdown grouped by utm_source > referer > Direct.
  Returns `{:ok, [%{source: String.t(), count: integer, percentage: float}]}` ordered desc.
  """
  def source_breakdown(tenant_id, job_id) do
    case verify_job_tenant(tenant_id, job_id) do
      {:error, _} = err -> err
      {:ok, _} -> {:ok, do_source_breakdown(tenant_id, job_id)}
    end
  end

  defp do_source_breakdown(tenant_id, job_id) do
    rows =
      Repo.all(
        from v in JobView,
          where: v.tenant_id == ^tenant_id and v.job_id == ^job_id,
          group_by:
            fragment("COALESCE(NULLIF(?, ''), NULLIF(?, ''), 'Direct')", v.utm_source, v.referer),
          select: {
            fragment("COALESCE(NULLIF(?, ''), NULLIF(?, ''), 'Direct')", v.utm_source, v.referer),
            count(v.id)
          },
          order_by: [desc: count(v.id)]
      )

    total = Enum.reduce(rows, 0, fn {_, c}, acc -> acc + c end)

    if total == 0 do
      []
    else
      Enum.map(rows, fn {source, count} ->
        %{source: source, count: count, percentage: Float.round(count / total * 100, 1)}
      end)
    end
  end

  @doc """
  Funnel for a job: total_views, total_applications, conversion_rate, tenant_avg_conversion_rate.
  """
  def funnel_for_job(tenant_id, job_id) do
    case verify_job_tenant(tenant_id, job_id) do
      {:error, _} = err -> err
      {:ok, _} -> {:ok, do_funnel(tenant_id, job_id)}
    end
  end

  defp do_funnel(tenant_id, job_id) do
    total_views =
      Repo.aggregate(
        from(v in JobView, where: v.tenant_id == ^tenant_id and v.job_id == ^job_id),
        :count
      )

    total_apps =
      Repo.aggregate(
        from(a in Treby.Pipeline.Application,
          where: a.tenant_id == ^tenant_id and a.job_id == ^job_id
        ),
        :count
      )

    conversion =
      if total_views == 0, do: 0.0, else: Float.round(total_apps / total_views * 100, 1)

    tenant_avg = tenant_avg_conversion(tenant_id)

    %{
      total_views: total_views,
      total_applications: total_apps,
      conversion_rate: conversion,
      tenant_avg_conversion_rate: tenant_avg
    }
  end

  @doc """
  Tenant average conversion rate across all jobs with views >0.
  Returns float or nil if no views.
  """
  def tenant_avg_conversion(tenant_id) do
    # For each job of tenant, compute conversion, then avg
    # Approach: total_apps_tenant / total_views_tenant * 100
    total_views =
      Repo.aggregate(from(v in JobView, where: v.tenant_id == ^tenant_id), :count)

    if total_views == 0 do
      nil
    else
      total_apps =
        Repo.aggregate(
          from(a in Treby.Pipeline.Application, where: a.tenant_id == ^tenant_id),
          :count
        )

      Float.round(total_apps / total_views * 100, 1)
    end
  end

  @doc """
  Returns `%{job_id => %{total_views, views_last_7_days}}` for all jobs of a tenant.
  Used to avoid N+1 in job list.
  """
  def summaries_for_tenant(tenant_id) do
    now = DateTime.utc_now()
    cutoff_7 = DateTime.add(now, -7 * 24 * 3600, :second)

    # Total per job
    totals =
      Repo.all(
        from v in JobView,
          where: v.tenant_id == ^tenant_id,
          group_by: v.job_id,
          select: {v.job_id, count(v.id)}
      )
      |> Map.new()

    last_7 =
      Repo.all(
        from v in JobView,
          where: v.tenant_id == ^tenant_id and v.viewed_at >= ^cutoff_7,
          group_by: v.job_id,
          select: {v.job_id, count(v.id)}
      )
      |> Map.new()

    totals
    |> Map.new(fn {jid, total} ->
      {jid, %{total_views: total, views_last_7_days: Map.get(last_7, jid, 0)}}
    end)
  end

  # -------------------------------------------------------------------
  # Internal helpers
  # -------------------------------------------------------------------

  defp verify_job_tenant(tenant_id, job_id) do
    case Repo.get(Job, job_id) do
      nil -> {:error, :not_found}
      %Job{tenant_id: ^tenant_id} = job -> {:ok, job}
      _ -> {:error, :not_found}
    end
  end
end
