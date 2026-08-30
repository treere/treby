defmodule TrebyWeb.AnalyticsLive.Index do
  use TrebyWeb, :live_view

  alias Treby.{Accounts, Tenants, Pipeline, Jobs}

  def mount(params, session, socket) do
    socket = set_locale_from_session(socket, session)

    {user, tenant} =
      cond do
        socket.assigns[:current_user] && socket.assigns[:current_tenant] ->
          {socket.assigns.current_user, socket.assigns.current_tenant}

        session["user_id"] && session["tenant_id"] ->
          {Accounts.get_user!(session["user_id"]), Tenants.get_tenant!(session["tenant_id"])}

        session["user_id"] ->
          u = Accounts.get_user!(session["user_id"])

          case Treby.Memberships.list_tenants_for_user(u.id) do
            [%{tenant: t} | _] -> {u, t}
            [] -> {u, nil}
          end

        true ->
          {nil, nil}
      end

    pipelines = Pipeline.list_pipelines(tenant.id)
    jobs = Jobs.list_jobs(tenant.id)

    {:ok,
     socket
     |> assign(current_user: user, current_tenant: tenant)
     |> assign(pipelines: pipelines)
     |> load_analytics(nil)
     |> assign(jobs: jobs)}
  end

  def handle_event("select_pipeline", %{"pipeline_id" => pipeline_id}, socket) do
    pipeline_id = if pipeline_id == "", do: nil, else: pipeline_id
    jobs = Jobs.list_jobs(socket.assigns.current_tenant.id)

    {:noreply,
     socket
     |> load_analytics(pipeline_id)
     |> assign(jobs: jobs)}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_user} locale={@locale}>
      <div class="p-8">
        <div class="flex justify-between items-center mb-8">
          <h1 class="text-2xl font-bold">Analytics</h1>
          <.form for={%{}} phx-change="select_pipeline" id="pipeline-selector-form">
            <select
              name="pipeline_id"
              class="select"
            >
              <option value="" selected={@selected_pipeline_id == nil}>All pipelines</option>
              <%= for pipeline <- @pipelines do %>
                <option
                  value={pipeline.id}
                  selected={@selected_pipeline_id == pipeline.id}
                >
                  {pipeline.name}
                </option>
              <% end %>
            </select>
          </.form>
        </div>

        <%!-- Metrics Cards --%>
        <div class="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
          <div class="bg-base-100 rounded-lg shadow p-6">
            <h3 class="text-sm font-medium text-base-content/50">Total Candidates</h3>
            <p class="mt-2 text-3xl font-bold text-base-content">
              {Enum.reduce(@pipeline_counts, 0, fn %{count: c}, acc -> acc + c end)}
            </p>
          </div>
          <div class="bg-base-100 rounded-lg shadow p-6">
            <h3 class="text-sm font-medium text-base-content/50">Avg. Time to Hire</h3>
            <p class="mt-2 text-3xl font-bold text-base-content">
              {if @avg_hire_days,
                do: "#{@avg_hire_days |> Decimal.to_float() |> Float.round(1)} days",
                else: "N/A"}
            </p>
          </div>
          <div class="bg-base-100 rounded-lg shadow p-6">
            <h3 class="text-sm font-medium text-base-content/50">Active Jobs</h3>
            <p class="mt-2 text-3xl font-bold text-base-content">
              {Enum.count(@jobs, &(&1.status == "open"))}
            </p>
          </div>
        </div>

        <%!-- Source Breakdown --%>
        <div :if={@source_breakdown != []} class="bg-base-100 rounded-lg shadow p-6 mb-8">
          <h2 class="text-lg font-semibold mb-4">Candidates by Source</h2>
          <div class="space-y-3">
            <div :for={item <- @source_breakdown} class="flex items-center gap-4">
              <div class="w-40 text-sm font-medium text-base-content/80">
                {item.source || "Unknown"}
              </div>
              <div class="flex-1 bg-base-200 rounded-full h-6">
                <div
                  class="h-6 rounded-full bg-blue-500 flex items-center justify-end pr-2"
                  style={"width: #{if @total_candidates > 0, do: max(item.count / @total_candidates * 100, 5), else: 5}%"}
                >
                  <span :if={item.count > 0} class="text-xs font-medium text-white">
                    {item.count}
                  </span>
                </div>
              </div>
              <span class="w-8 text-sm text-base-content/70 text-right">{item.count}</span>
            </div>
          </div>
        </div>

        <%!-- Pipeline Overview --%>
        <div class="bg-base-100 rounded-lg shadow p-6 mb-8">
          <h2 class="text-lg font-semibold mb-4">Pipeline Overview</h2>
          <div class="space-y-3">
            <div :for={item <- @pipeline_counts} class="flex items-center gap-4">
              <div class="w-32 flex items-center gap-2">
                <div class="w-3 h-3 rounded-full" style={"background-color: #{item.stage.color}"}>
                </div>
                <span class="text-sm font-medium text-base-content/80">{item.stage.name}</span>
              </div>
              <div class="flex-1 bg-base-200 rounded-full h-6">
                <div
                  class="h-6 rounded-full flex items-center justify-end pr-2"
                  style={
                    "background-color: #{item.stage.color}; width: #{if Enum.reduce(@pipeline_counts, 0, fn %{count: c}, acc -> acc + c end) > 0, do: max(item.count / Enum.reduce(@pipeline_counts, 0, fn %{count: c}, acc -> acc + c end) * 100, 5), else: 5}%"
                  }
                >
                  <span :if={item.count > 0} class="text-xs font-medium text-white">
                    {item.count}
                  </span>
                </div>
              </div>
              <span class="w-8 text-sm text-base-content/70 text-right">{item.count}</span>
            </div>
          </div>
        </div>

        <%!-- Time in Stage --%>
        <div :if={@time_in_stage != []} class="bg-base-100 rounded-lg shadow p-6 mb-8">
          <h2 class="text-lg font-semibold mb-4">Time in Stage (Avg. Days)</h2>
          <div class="space-y-3">
            <div :for={item <- @time_in_stage} class="flex items-center gap-4">
              <div class="w-32 flex items-center gap-2">
                <div
                  class="w-3 h-3 rounded-full"
                  style={"background-color: #{if item.stage, do: item.stage.color, else: "#6B7280"}"}
                >
                </div>
                <span class="text-sm font-medium text-base-content/80">
                  {if item.stage, do: item.stage.name, else: "Unknown"}
                </span>
              </div>
              <div class="flex-1 bg-base-200 rounded-full h-6">
                <div
                  class={[
                    "h-6 rounded-full flex items-center justify-end pr-2",
                    if(item.is_bottleneck, do: "bg-red-500", else: "bg-blue-500")
                  ]}
                  style={"width: #{min(item.avg_days * 10, 100)}%"}
                >
                  <span :if={item.avg_days > 0} class="text-xs font-medium text-white">
                    {Float.round(item.avg_days, 1)}d
                  </span>
                </div>
              </div>
              <span class="w-16 text-sm text-base-content/70 text-right">
                {Float.round(item.avg_days, 1)}d
              </span>
            </div>
          </div>
        </div>

        <%!-- Hiring Funnel --%>
        <div class="bg-base-100 rounded-lg shadow p-6 mb-8">
          <h2 class="text-lg font-semibold mb-4">Hiring Funnel</h2>
          <div class="flex flex-col items-center gap-1">
            <div
              :for={{item, idx} <- Enum.with_index(@pipeline_counts)}
              class="flex items-center gap-4 w-full max-w-lg"
            >
              <div class="w-28 text-right flex items-center justify-end gap-2">
                <div class="w-3 h-3 rounded-full" style={"background-color: #{item.stage.color}"}>
                </div>
                <span class="text-sm font-medium text-base-content/80">{item.stage.name}</span>
              </div>
              <div class="flex-1 flex justify-center">
                <div
                  class="h-8 rounded flex items-center justify-center transition-all"
                  style={
                    "background-color: #{item.stage.color};
                     width: #{total = Enum.reduce(@pipeline_counts, 0, fn %{count: c}, acc -> acc + c end);
                               if total > 0, do: max(item.count / total * 100, item.count > 0 && 8 || 0), else: 0}%"
                  }
                >
                  <span :if={item.count > 0} class="text-xs font-semibold text-white">
                    {item.count}
                  </span>
                </div>
              </div>
              <span class="w-10 text-sm text-base-content/50 text-right">
                {total = Enum.reduce(@pipeline_counts, 0, fn %{count: c}, acc -> acc + c end)
                if total > 0, do: "#{trunc(item.count / total * 100)}%", else: "0%"}
              </span>
            </div>
          </div>
        </div>

        <%!-- Conversion Rates --%>
        <div :if={@conversion_rates != []} class="bg-base-100 rounded-lg shadow p-6">
          <h2 class="text-lg font-semibold mb-4">Stage Conversion Rates</h2>
          <div class="space-y-2">
            <div :for={rate <- @conversion_rates} class="flex items-center gap-3 text-sm">
              <span class="text-base-content/80">{rate.from.name}</span>
              <.icon name="hero-arrow-right" class="w-4 h-4 text-base-content/40" />
              <span class="text-base-content/80">{rate.to.name}</span>
              <span class={[
                "font-medium ml-auto",
                if(rate.rate >= 50, do: "text-green-600", else: "text-red-600")
              ]}>
                {rate.rate}%
              </span>
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  defp load_analytics(socket, pipeline_id) do
    tenant_id = socket.assigns.current_tenant.id
    pipeline_counts = Pipeline.pipeline_counts_per_stage(tenant_id, pipeline_id)
    avg_hire_days = Pipeline.average_time_to_hire(tenant_id, pipeline_id)
    time_in_stage = Pipeline.time_in_stage_metrics(tenant_id, pipeline_id)
    conversion_rates = Pipeline.stage_conversion_rates(tenant_id, pipeline_id)

    # Source breakdown
    source_breakdown = Pipeline.source_breakdown(tenant_id, pipeline_id)
    total_candidates = Enum.reduce(source_breakdown, 0, fn %{count: c}, acc -> acc + c end)

    avg_time =
      if time_in_stage != [] do
        time_in_stage |> Enum.map(& &1.avg_days) |> Enum.sum() |> Kernel./(length(time_in_stage))
      else
        0
      end

    time_in_stage =
      Enum.map(time_in_stage, fn item ->
        Map.put(item, :is_bottleneck, item.avg_days > avg_time && item.avg_days > 0)
      end)

    socket
    |> assign(selected_pipeline_id: pipeline_id)
    |> assign(pipeline_counts: pipeline_counts)
    |> assign(avg_hire_days: avg_hire_days)
    |> assign(time_in_stage: time_in_stage)
    |> assign(conversion_rates: conversion_rates)
    |> assign(source_breakdown: source_breakdown)
    |> assign(total_candidates: total_candidates)
  end
end
