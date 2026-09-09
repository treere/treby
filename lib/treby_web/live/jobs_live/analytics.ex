defmodule TrebyWeb.JobsLive.Analytics do
  use TrebyWeb, :live_view

  alias Treby.{Accounts, Tenants, Jobs, JobViews}

  def mount(%{"id" => id}, session, socket) do
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

    case Jobs.get_job(tenant.id, id) do
      nil ->
        {:ok, redirect(socket, to: ~p"/404")}

      job ->
        {:ok,
         socket
         |> assign(current_user: user, current_tenant: tenant)
         |> assign(job: job)
         |> assign(selected_period: 30)
         |> load_analytics()}
    end
  end

  def handle_event("select_period", %{"period" => period}, socket) do
    period = String.to_integer(period)
    {:noreply, socket |> assign(selected_period: period) |> load_analytics()}
  end

  defp load_analytics(socket) do
    tenant_id = socket.assigns.current_tenant.id
    job_id = socket.assigns.job.id
    days = socket.assigns.selected_period

    summary =
      case JobViews.get_summary(tenant_id, job_id) do
        {:ok, s} ->
          s

        {:error, :not_found} ->
          %{
            total_views: 0,
            unique_views: 0,
            views_last_7_days: 0,
            views_last_30_days: 0,
            views_last_90_days: 0,
            avg_daily_views: 0.0
          }
      end

    {:ok, daily} = JobViews.daily_breakdown(tenant_id, job_id, days)
    {:ok, monthly} = JobViews.monthly_breakdown(tenant_id, job_id, 12)
    {:ok, sources} = JobViews.source_breakdown(tenant_id, job_id)
    {:ok, funnel} = JobViews.funnel_for_job(tenant_id, job_id)

    socket
    |> assign(summary: summary)
    |> assign(daily_breakdown: daily)
    |> assign(monthly_breakdown: monthly)
    |> assign(source_breakdown: sources)
    |> assign(funnel: funnel)
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_user} locale={@locale}>
      <div class="p-8">
        <.page_header
          title={gettext("%{title} — Analytics", title: @job.title)}
          subtitle={gettext("Views and conversion for this position")}
          breadcrumbs={[
            %{label: gettext("Jobs"), href: ~p"/app/jobs"},
            %{label: @job.title, href: ~p"/app/jobs/#{@job.id}"},
            %{label: gettext("Analytics")}
          ]}
        />
        <div :if={@job.status == "closed"} class="mb-4">
          <.badge variant="default">{gettext("Closed — showing historical data")}</.badge>
        </div>

        <%!-- KPI Cards --%>
        <div class="grid grid-cols-1 md:grid-cols-3 lg:grid-cols-6 gap-4 mb-8">
          <div class="bg-white dark:bg-zinc-800 rounded-xl border border-zinc-200 dark:border-zinc-700 shadow-sm p-4">
            <h3 class="text-xs font-medium text-zinc-500 dark:text-zinc-400 uppercase tracking-wide">
              Total Views
            </h3>
            <p class="mt-2 text-2xl font-bold text-zinc-900 dark:text-zinc-100">
              {@summary.total_views}
            </p>
          </div>
          <div class="bg-white dark:bg-zinc-800 rounded-xl border border-zinc-200 dark:border-zinc-700 shadow-sm p-4">
            <h3 class="text-xs font-medium text-zinc-500 dark:text-zinc-400 uppercase tracking-wide">
              Unique Views
            </h3>
            <p class="mt-2 text-2xl font-bold text-zinc-900 dark:text-zinc-100">
              {@summary.unique_views}
            </p>
          </div>
          <div class="bg-white dark:bg-zinc-800 rounded-xl border border-zinc-200 dark:border-zinc-700 shadow-sm p-4">
            <h3 class="text-xs font-medium text-zinc-500 dark:text-zinc-400 uppercase tracking-wide">
              Last 7 Days
            </h3>
            <p class="mt-2 text-2xl font-bold text-zinc-900 dark:text-zinc-100">
              {@summary.views_last_7_days}
            </p>
          </div>
          <div class="bg-white dark:bg-zinc-800 rounded-xl border border-zinc-200 dark:border-zinc-700 shadow-sm p-4">
            <h3 class="text-xs font-medium text-zinc-500 dark:text-zinc-400 uppercase tracking-wide">
              Last 30 Days
            </h3>
            <p class="mt-2 text-2xl font-bold text-zinc-900 dark:text-zinc-100">
              {@summary.views_last_30_days}
            </p>
          </div>
          <div class="bg-white dark:bg-zinc-800 rounded-xl border border-zinc-200 dark:border-zinc-700 shadow-sm p-4">
            <h3 class="text-xs font-medium text-zinc-500 dark:text-zinc-400 uppercase tracking-wide">
              Avg / Day
            </h3>
            <p class="mt-2 text-2xl font-bold text-zinc-900 dark:text-zinc-100">
              {if @summary.avg_daily_views == 0.0, do: "N/A", else: "#{@summary.avg_daily_views}"}
            </p>
          </div>
          <div class="bg-white dark:bg-zinc-800 rounded-xl border border-zinc-200 dark:border-zinc-700 shadow-sm p-4">
            <h3 class="text-xs font-medium text-zinc-500 dark:text-zinc-400 uppercase tracking-wide">
              Conversion
            </h3>
            <p class="mt-2 text-2xl font-bold text-zinc-900 dark:text-zinc-100">
              {@funnel.conversion_rate}%
            </p>
            <p class="text-xs text-zinc-500 dark:text-zinc-400">
              {@funnel.total_applications} applications
            </p>
          </div>
        </div>

        <.empty_state
          :if={@summary.total_views == 0}
          icon="hero-chart-bar"
          title={gettext("No views yet")}
          description={
            gettext(
              "When visitors view the public job page, you'll see daily and monthly trends, traffic sources, and the view→application funnel here."
            )
          }
          class="mb-8"
        />

        <div class="space-y-8">
          <%!-- Daily chart --%>
          <div
            id="daily-views-card"
            class="chart-card bg-white dark:bg-zinc-800 rounded-xl border border-zinc-200 dark:border-zinc-700 shadow-sm p-6"
          >
            <div class="flex items-center justify-between mb-4">
              <h2 class="text-lg font-semibold text-zinc-900 dark:text-zinc-100">
                {gettext("Daily Views")}
              </h2>
              <.form
                for={%{}}
                id="period-selector-form"
                phx-change="select_period"
                class="flex items-center gap-2"
              >
                <label class="text-sm text-zinc-500 dark:text-zinc-400">{gettext("Period")}</label>
                <select
                  name="period"
                  class="w-full rounded-lg border border-zinc-200 dark:border-zinc-700 bg-white dark:bg-zinc-800 px-3 py-2 text-sm text-zinc-900 dark:text-zinc-100 focus:outline-none focus:ring-2 focus:ring-orange-500 focus:border-orange-500 select-sm"
                >
                  <option value="7" selected={@selected_period == 7}>{gettext("Last 7 days")}</option>
                  <option value="30" selected={@selected_period == 30}>
                    {gettext("Last 30 days")}
                  </option>
                  <option value="90" selected={@selected_period == 90}>
                    {gettext("Last 90 days")}
                  </option>
                </select>
              </.form>
            </div>

            <div class="chart-card__body">
              <%= if Enum.all?(@daily_breakdown, &(&1.count == 0)) do %>
                <div
                  id="daily-views-empty"
                  class="w-full flex flex-col items-center justify-center py-16 px-6 border border-dashed border-zinc-200 dark:border-zinc-700 rounded-lg text-center"
                >
                  <.icon name="hero-chart-bar" class="w-8 h-8 text-zinc-400 dark:text-zinc-500 mb-2" />
                  <p class="text-sm font-medium text-zinc-700 dark:text-zinc-300">
                    {gettext("No views in this period")}
                  </p>
                  <p class="text-xs text-zinc-500 dark:text-zinc-400 mt-1">
                    {gettext("Share the public link to start tracking views")}
                  </p>
                </div>
              <% else %>
                <div id="daily-views-chart" class="contex-chart w-full">
                  {TrebyWeb.Charts.daily_plot(@daily_breakdown, @selected_period)
                  |> TrebyWeb.Charts.to_svg()}
                </div>
              <% end %>
            </div>
          </div>

          <%!-- Monthly breakdown --%>
          <div
            id="monthly-views-card"
            class="chart-card bg-white dark:bg-zinc-800 rounded-xl border border-zinc-200 dark:border-zinc-700 shadow-sm p-6"
          >
            <h2 class="text-lg font-semibold text-zinc-900 dark:text-zinc-100 mb-4">
              {gettext("Monthly Views (Last 12 Months)")}
            </h2>
            <div class="chart-card__body">
              <%= if Enum.all?(@monthly_breakdown, &(&1.count == 0)) do %>
                <div
                  id="monthly-views-empty"
                  class="w-full flex flex-col items-center justify-center py-16 px-6 border border-dashed border-zinc-200 dark:border-zinc-700 rounded-lg text-center"
                >
                  <.icon name="hero-chart-bar" class="w-8 h-8 text-zinc-400 dark:text-zinc-500 mb-2" />
                  <p class="text-sm font-medium text-zinc-700 dark:text-zinc-300">
                    {gettext("No monthly data yet")}
                  </p>
                  <p class="text-xs text-zinc-500 dark:text-zinc-400 mt-1">
                    {gettext("Views will appear here grouped by month")}
                  </p>
                </div>
              <% else %>
                <div id="monthly-views-chart" class="contex-chart w-full">
                  {TrebyWeb.Charts.monthly_plot(@monthly_breakdown) |> TrebyWeb.Charts.to_svg()}
                </div>
              <% end %>
            </div>
          </div>

          <%!-- Source breakdown --%>
          <div
            id="traffic-sources-card"
            class="chart-card bg-white dark:bg-zinc-800 rounded-xl border border-zinc-200 dark:border-zinc-700 shadow-sm p-6"
          >
            <h2 class="text-lg font-semibold text-zinc-900 dark:text-zinc-100 mb-4">
              {gettext("Traffic Sources")}
            </h2>
            <div class="chart-card__body">
              <%= if @source_breakdown == [] do %>
                <div
                  id="traffic-sources-empty"
                  class="w-full flex flex-col items-center justify-center py-16 px-6 border border-dashed border-zinc-200 dark:border-zinc-700 rounded-lg text-center"
                >
                  <.icon name="hero-chart-bar" class="w-8 h-8 text-zinc-400 dark:text-zinc-500 mb-2" />
                  <p class="text-sm font-medium text-zinc-700 dark:text-zinc-300">
                    {gettext("No source data yet")}
                  </p>
                  <p class="text-xs text-zinc-500 dark:text-zinc-400 mt-1">
                    {gettext("Share with utm_source to track campaigns")}
                  </p>
                </div>
              <% else %>
                <div id="traffic-sources-chart" class="contex-chart w-full">
                  {TrebyWeb.Charts.sources_plot(@source_breakdown) |> TrebyWeb.Charts.to_svg()}
                </div>
              <% end %>
            </div>
          </div>

          <%!-- Funnel --%>
          <div
            id="funnel-card"
            class="bg-white dark:bg-zinc-800 rounded-xl border border-zinc-200 dark:border-zinc-700 shadow-sm p-6"
          >
            <h2 class="text-lg font-semibold text-zinc-900 dark:text-zinc-100 mb-4">
              {gettext("View → Application Funnel")}
            </h2>
            <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
              <div class="text-center p-4 bg-zinc-50 dark:bg-zinc-800 rounded-lg">
                <p class="text-xs uppercase tracking-wide text-zinc-500 dark:text-zinc-400">
                  {gettext("Views")}
                </p>
                <p class="text-2xl font-bold mt-1">{@funnel.total_views}</p>
              </div>
              <div class="flex items-center justify-center">
                <.icon name="hero-arrow-right" class="w-6 h-6 text-zinc-900 dark:text-zinc-100/30" />
                <span class="ml-2 text-sm font-medium text-zinc-500 dark:text-zinc-400">
                  {if @funnel.total_views > 0,
                    do: "#{@funnel.conversion_rate}% converted",
                    else: "0% conversion"}
                </span>
              </div>
              <div class="text-center p-4 bg-zinc-50 dark:bg-zinc-800 rounded-lg">
                <p class="text-xs uppercase tracking-wide text-zinc-500 dark:text-zinc-400">
                  {gettext("Applications")}
                </p>
                <p class="text-2xl font-bold mt-1">{@funnel.total_applications}</p>
              </div>
            </div>
            <p
              :if={@funnel.tenant_avg_conversion_rate}
              class="mt-4 text-sm text-zinc-500 dark:text-zinc-400 text-center"
            >
              Tenant average conversion: {@funnel.tenant_avg_conversion_rate}% across all jobs
            </p>
            <p
              :if={is_nil(@funnel.tenant_avg_conversion_rate)}
              class="mt-4 text-sm text-zinc-500 dark:text-zinc-400 text-center"
            >
              No tenant average yet — more views needed.
            </p>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
