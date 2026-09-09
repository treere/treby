defmodule TrebyWeb.Charts do
  @moduledoc """
  Server-side chart helpers for analytics pages using Contex.

  Each function builds a `Contex.Plot` and returns SVG-safe HTML via `to_svg/1`.
  Empty or all-zero inputs return `nil` so callers can render a placeholder.
  """

  alias Contex.{Dataset, Plot}

  @daily_palette ["ea580c"]
  @monthly_palette ["8b5cf6"]
  @sources_palette [
    "ea580c",
    "3b82f6",
    "22c55e",
    "a855f7",
    "f59e0b",
    "06b6d4",
    "06b6d4",
    "ec4899"
  ]
  @pipeline_default_palette ["6b7280"]

  @doc """
  Daily views line chart (PointPlot with TimeScale).

  `daily_breakdown` is a list of `%{date: Date.t(), count: integer}`.
  `days` controls axis rotation (45° when >30).
  Returns `Contex.Plot.t()` or `nil` when all counts are zero.
  """
  def daily_plot(daily_breakdown, days \\ 30) when is_list(daily_breakdown) do
    if Enum.all?(daily_breakdown, &(&1.count == 0)) do
      nil
    else
      data =
        Enum.map(daily_breakdown, fn %{date: date, count: count} ->
          # Use DateTime at noon UTC so TimeScale treats it as continuous
          dt = DateTime.new!(date, ~T[12:00:00], "Etc/UTC")
          %{x: dt, y: count}
        end)

      dataset = Dataset.new(data)

      opts = [
        mapping: %{x_col: :x, y_cols: [:y]},
        colour_palette: @daily_palette,
        data_labels: false,
        axis_label_rotation: if(days > 30, do: 45, else: 0),
        x_label: "",
        y_label: "Views",
        title: ""
      ]

      Plot.new(dataset, Contex.PointPlot, 600, 300, opts)
    end
  end

  @doc """
  Monthly views bar chart (12 months, vertical).
  `monthly_breakdown` is a list of `%{month: Date.t(), count: integer}`.
  """
  def monthly_plot(monthly_breakdown) when is_list(monthly_breakdown) do
    if Enum.all?(monthly_breakdown, &(&1.count == 0)) do
      nil
    else
      data =
        Enum.map(monthly_breakdown, fn %{month: month, count: count} ->
          label = Calendar.strftime(month, "%b %Y")
          %{label: label, count: count}
        end)

      dataset = Dataset.new(data)

      opts = [
        mapping: %{category_col: :label, value_cols: [:count]},
        colour_palette: @monthly_palette,
        data_labels: true,
        type: :stacked,
        orientation: :vertical,
        axis_label_rotation: 45,
        y_label: "Views",
        x_label: ""
      ]

      Plot.new(dataset, Contex.BarChart, 600, 320, opts)
    end
  end

  @doc """
  Traffic sources pie chart.
  `source_breakdown` is a list of `%{source: String.t(), count: integer, percentage: float}`.
  """
  def sources_plot(source_breakdown) when is_list(source_breakdown) do
    case source_breakdown do
      [] ->
        nil

      list when is_list(list) ->
        data =
          Enum.map(list, fn %{source: source, count: count} ->
            %{source: source, count: count}
          end)

        dataset = Dataset.new(data)

        opts = [
          mapping: %{category_col: :source, value_col: :count},
          colour_palette: @sources_palette,
          data_labels: true,
          legend_setting: :legend_right,
          title: ""
        ]

        Plot.new(dataset, Contex.PieChart, 520, 320, opts)
    end
  end

  @doc """
  Pipeline overview horizontal bar chart.
  `pipeline_counts` is a list of `%{stage: %{name: String.t(), color: String.t()}, count: integer}`.
  """
  def pipeline_plot(pipeline_counts) when is_list(pipeline_counts) do
    if pipeline_counts == [] or Enum.all?(pipeline_counts, &(&1.count == 0)) do
      nil
    else
      data =
        Enum.map(pipeline_counts, fn %{stage: stage, count: count} ->
          %{stage: stage.name, count: count}
        end)

      dataset = Dataset.new(data)

      palette =
        pipeline_counts
        |> Enum.map(fn %{stage: stage} ->
          stage.color |> to_string() |> String.trim_leading("#") |> String.downcase()
        end)
        |> Enum.map(fn c -> if c == "", do: "6b7280", else: c end)
        |> case do
          [] -> @pipeline_default_palette
          list -> list
        end

      opts = [
        mapping: %{category_col: :stage, value_cols: [:count]},
        colour_palette: palette,
        data_labels: true,
        orientation: :horizontal,
        type: :stacked
      ]

      Plot.new(dataset, Contex.BarChart, 600, 280, opts)
    end
  end

  @doc """
  Time in stage horizontal bar chart.
  `time_in_stage` is a list of `%{stage: %{name: String.t(), color: String.t()} | nil, avg_days: float}`.
  """
  def time_in_stage_plot(time_in_stage) when is_list(time_in_stage) do
    if time_in_stage == [] do
      nil
    else
      data =
        Enum.map(time_in_stage, fn item ->
          name = if item.stage, do: item.stage.name, else: "Unknown"
          avg = Float.round(item.avg_days * 1.0, 1)
          %{stage: name, avg_days: avg}
        end)

      dataset = Dataset.new(data)

      opts = [
        mapping: %{category_col: :stage, value_cols: [:avg_days]},
        colour_palette: ["3b82f6"],
        data_labels: true,
        orientation: :horizontal,
        type: :stacked,
        y_label: "Avg days"
      ]

      Plot.new(dataset, Contex.BarChart, 600, 280, opts)
    end
  end

  @doc """
  Render a Contex plot to safe SVG HTML.
  Returns `nil` when plot is `nil`.
  """
  def to_svg(nil), do: nil

  def to_svg(%Plot{} = plot) do
    Plot.to_svg(plot)
  end
end
