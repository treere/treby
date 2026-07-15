defmodule TrebyWeb.AnalyticsLive.Index do
  use TrebyWeb, :live_view

  alias Treby.{Accounts, Tenants, Pipeline, Jobs}

  def mount(_params, session, socket) do
    user = Accounts.get_user!(session["user_id"])
    tenant = Tenants.get_tenant!(session["tenant_id"])

    pipeline_counts = Pipeline.pipeline_counts_per_stage(tenant.id)
    avg_hire_days = Pipeline.average_time_to_hire(tenant.id)
    conversion_rates = Pipeline.stage_conversion_rates(tenant.id)
    jobs = Jobs.list_jobs(tenant.id)

    {:ok,
     socket
     |> assign(current_user: user, current_tenant: tenant)
     |> assign(pipeline_counts: pipeline_counts)
     |> assign(avg_hire_days: avg_hire_days)
     |> assign(conversion_rates: conversion_rates)
     |> assign(jobs: jobs)}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_user}>
      <div class="p-8">
        <h1 class="text-2xl font-bold mb-8">Analytics</h1>

        <%!-- Metrics Cards --%>
        <div class="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
          <div class="bg-white rounded-lg shadow p-6">
            <h3 class="text-sm font-medium text-gray-500">Total Candidates</h3>
            <p class="mt-2 text-3xl font-bold text-gray-900">
              {Enum.reduce(@pipeline_counts, 0, fn %{count: c}, acc -> acc + c end)}
            </p>
          </div>
          <div class="bg-white rounded-lg shadow p-6">
            <h3 class="text-sm font-medium text-gray-500">Avg. Time to Hire</h3>
            <p class="mt-2 text-3xl font-bold text-gray-900">
              {if @avg_hire_days, do: "#{Float.round(@avg_hire_days * 1.0, 1)} days", else: "N/A"}
            </p>
          </div>
          <div class="bg-white rounded-lg shadow p-6">
            <h3 class="text-sm font-medium text-gray-500">Active Jobs</h3>
            <p class="mt-2 text-3xl font-bold text-gray-900">
              {Enum.count(@jobs, &(&1.status == "open"))}
            </p>
          </div>
        </div>

        <%!-- Pipeline Overview --%>
        <div class="bg-white rounded-lg shadow p-6 mb-8">
          <h2 class="text-lg font-semibold mb-4">Pipeline Overview</h2>
          <div class="space-y-3">
            <div :for={item <- @pipeline_counts} class="flex items-center gap-4">
              <div class="w-32 flex items-center gap-2">
                <div class="w-3 h-3 rounded-full" style={"background-color: #{item.stage.color}"}>
                </div>
                <span class="text-sm font-medium text-gray-700">{item.stage.name}</span>
              </div>
              <div class="flex-1 bg-gray-100 rounded-full h-6">
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
              <span class="w-8 text-sm text-gray-600 text-right">{item.count}</span>
            </div>
          </div>
        </div>

        <%!-- Conversion Rates --%>
        <div :if={@conversion_rates != []} class="bg-white rounded-lg shadow p-6">
          <h2 class="text-lg font-semibold mb-4">Stage Conversion Rates</h2>
          <div class="space-y-3">
            <div :for={rate <- @conversion_rates} class="flex items-center gap-4">
              <span class="text-sm text-gray-700 w-48">
                {rate.from.name} &rarr; {rate.to.name}
              </span>
              <div class="flex-1 bg-gray-100 rounded-full h-4">
                <div
                  class="h-4 rounded-full bg-green-500"
                  style={"width: #{rate.rate}%"}
                >
                </div>
              </div>
              <span class="w-12 text-sm font-medium text-gray-700 text-right">{rate.rate}%</span>
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
