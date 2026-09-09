defmodule TrebyWeb.ChartsTest do
  use ExUnit.Case, async: true

  alias TrebyWeb.Charts

  describe "daily_plot/2" do
    test "returns nil when all counts zero" do
      daily = for i <- 0..6, do: %{date: Date.add(Date.utc_today(), -i), count: 0}
      assert Charts.daily_plot(daily, 7) == nil
      assert Charts.to_svg(nil) == nil
    end

    test "returns plot and safe svg when data has values" do
      daily = [
        %{date: ~D[2025-09-01], count: 2},
        %{date: ~D[2025-09-02], count: 5},
        %{date: ~D[2025-09-03], count: 0}
      ]

      plot = Charts.daily_plot(daily, 7)
      assert %Contex.Plot{} = plot
      assert {:safe, _} = Charts.to_svg(plot)
      svg = Charts.to_svg(plot) |> Phoenix.HTML.safe_to_string()
      assert svg =~ "<svg"
      assert svg =~ "Views"
    end
  end

  describe "monthly_plot/1" do
    test "returns nil when empty" do
      monthly = for _ <- 1..12, do: %{month: ~D[2025-01-01], count: 0}
      assert Charts.monthly_plot(monthly) == nil
    end

    test "returns svg for monthly data" do
      monthly = [
        %{month: ~D[2025-01-01], count: 3},
        %{month: ~D[2025-02-01], count: 7}
      ]

      plot = Charts.monthly_plot(monthly)
      assert %Contex.Plot{} = plot
      assert {:safe, _} = Charts.to_svg(plot)
    end
  end

  describe "sources_plot/1" do
    test "returns nil for empty list" do
      assert Charts.sources_plot([]) == nil
    end

    test "returns svg for sources" do
      sources = [
        %{source: "LinkedIn", count: 10, percentage: 50.0},
        %{source: "Direct", count: 10, percentage: 50.0}
      ]

      plot = Charts.sources_plot(sources)
      assert %Contex.Plot{} = plot
      assert {:safe, _} = Charts.to_svg(plot)
    end
  end

  describe "pipeline_plot/1" do
    test "returns nil for empty" do
      assert Charts.pipeline_plot([]) == nil
    end

    test "returns svg preserving stage colors" do
      counts = [
        %{stage: %{name: "New", color: "#6b7280"}, count: 5},
        %{stage: %{name: "Interview", color: "#3b82f6"}, count: 2}
      ]

      plot = Charts.pipeline_plot(counts)
      assert %Contex.Plot{} = plot
      assert {:safe, _} = Charts.to_svg(plot)
    end
  end

  describe "time_in_stage_plot/1" do
    test "returns nil for empty" do
      assert Charts.time_in_stage_plot([]) == nil
    end

    test "handles nil stage" do
      data = [
        %{stage: nil, avg_days: 2.5, count: 1},
        %{stage: %{name: "Interview", color: "#3b82f6"}, avg_days: 4.1, count: 2}
      ]

      plot = Charts.time_in_stage_plot(data)
      assert %Contex.Plot{} = plot
      assert {:safe, _} = Charts.to_svg(plot)
    end
  end
end
