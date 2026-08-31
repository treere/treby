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
          <div class="bg-base-100 rounded-lg shadow p-4">
            <h3 class="text-xs font-medium text-base-content/50 uppercase tracking-wide">
              Total Views
            </h3>
            <p class="mt-2 text-2xl font-bold text-base-content">{@summary.total_views}</p>
          </div>
          <div class="bg-base-100 rounded-lg shadow p-4">
            <h3 class="text-xs font-medium text-base-content/50 uppercase tracking-wide">
              Unique Views
            </h3>
            <p class="mt-2 text-2xl font-bold text-base-content">{@summary.unique_views}</p>
          </div>
          <div class="bg-base-100 rounded-lg shadow p-4">
            <h3 class="text-xs font-medium text-base-content/50 uppercase tracking-wide">
              Last 7 Days
            </h3>
            <p class="mt-2 text-2xl font-bold text-base-content">{@summary.views_last_7_days}</p>
          </div>
          <div class="bg-base-100 rounded-lg shadow p-4">
            <h3 class="text-xs font-medium text-base-content/50 uppercase tracking-wide">
              Last 30 Days
            </h3>
            <p class="mt-2 text-2xl font-bold text-base-content">{@summary.views_last_30_days}</p>
          </div>
          <div class="bg-base-100 rounded-lg shadow p-4">
            <h3 class="text-xs font-medium text-base-content/50 uppercase tracking-wide">
              Avg / Day
            </h3>
            <p class="mt-2 text-2xl font-bold text-base-content">
              {if @summary.avg_daily_views == 0.0, do: "N/A", else: "#{@summary.avg_daily_views}"}
            </p>
          </div>
          <div class="bg-base-100 rounded-lg shadow p-4">
            <h3 class="text-xs font-medium text-base-content/50 uppercase tracking-wide">
              Conversion
            </h3>
            <p class="mt-2 text-2xl font-bold text-base-content">{@funnel.conversion_rate}%</p>
            <p class="text-xs text-base-content/50">{@funnel.total_applications} applications</p>
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

        <div :if={@summary.total_views > 0} class="space-y-8">
          <%!-- Daily chart --%>
          <div class="bg-base-100 rounded-lg shadow p-6">
            <div class="flex items-center justify-between mb-4">
              <h2 class="text-lg font-semibold">{gettext("Daily Views")}</h2>
              <.form
                for={%{}}
                id="period-selector-form"
                phx-change="select_period"
                class="flex items-center gap-2"
              >
                <label class="text-sm text-base-content/70">{gettext("Period")}</label>
                <select name="period" class="select select-sm">
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

            <div
              :if={Enum.all?(@daily_breakdown, &(&1.count == 0))}
              class="text-center text-base-content/50 py-8"
            >
              No views in this period
            </div>

            <div :if={not Enum.all?(@daily_breakdown, &(&1.count == 0))} class="space-y-2">
              <% max = @daily_breakdown |> Enum.map(& &1.count) |> Enum.max() %>
              <div :for={item <- @daily_breakdown} class="flex items-center gap-3 text-sm">
                <span class="w-24 text-xs text-base-content/60 text-right">
                  {Calendar.strftime(item.date, "%b %d")}
                </span>
                <div class="flex-1 bg-base-200 rounded-full h-5">
                  <div
                    class="h-5 rounded-full bg-blue-500 flex items-center justify-end pr-2"
                    style={"width: #{if max > 0, do: max(item.count / max * 100, item.count > 0 && 8 || 0), else: 0}%"}
                  >
                    <span :if={item.count > 0} class="text-[11px] font-medium text-white">
                      {item.count}
                    </span>
                  </div>
                </div>
                <span class="w-8 text-xs text-base-content/60">{item.count}</span>
              </div>
            </div>
          </div>

          <%!-- Monthly breakdown --%>
          <div class="bg-base-100 rounded-lg shadow p-6">
            <h2 class="text-lg font-semibold mb-4">{gettext("Monthly Views (Last 12 Months)")}</h2>
            <div
              :if={Enum.all?(@monthly_breakdown, &(&1.count == 0))}
              class="text-center text-base-content/50 py-8"
            >
              No monthly data yet
            </div>
            <div :if={not Enum.all?(@monthly_breakdown, &(&1.count == 0))} class="space-y-2">
              <% max_m = @monthly_breakdown |> Enum.map(& &1.count) |> Enum.max() %>
              <div :for={item <- @monthly_breakdown} class="flex items-center gap-3 text-sm">
                <span class="w-24 text-xs text-base-content/60 text-right">
                  {Calendar.strftime(item.month, "%b %Y")}
                </span>
                <div class="flex-1 bg-base-200 rounded-full h-5">
                  <div
                    class="h-5 rounded-full bg-purple-500 flex items-center justify-end pr-2"
                    style={"width: #{if max_m > 0, do: max(item.count / max_m * 100, item.count > 0 && 8 || 0), else: 0}%"}
                  >
                    <span :if={item.count > 0} class="text-[11px] font-medium text-white">
                      {item.count}
                    </span>
                  </div>
                </div>
                <span class="w-8 text-xs text-base-content/60">{item.count}</span>
              </div>
            </div>
          </div>

          <%!-- Source breakdown --%>
          <div class="bg-base-100 rounded-lg shadow p-6">
            <h2 class="text-lg font-semibold mb-4">{gettext("Traffic Sources")}</h2>
            <div :if={@source_breakdown == []} class="text-center text-base-content/50 py-8">
              No source data yet
            </div>
            <div :if={@source_breakdown != []} class="space-y-3">
              <div :for={item <- @source_breakdown} class="flex items-center gap-4">
                <span class="w-32 text-sm font-medium text-base-content/80">{item.source}</span>
                <div class="flex-1 bg-base-200 rounded-full h-5">
                  <div
                    class="h-5 rounded-full bg-green-500 flex items-center justify-end pr-2"
                    style={"width: #{max(item.percentage, 5)}%"}
                  >
                    <span class="text-[11px] font-medium text-white">{item.count}</span>
                  </div>
                </div>
                <span class="w-16 text-xs text-base-content/60 text-right">{item.percentage}%</span>
              </div>
            </div>
          </div>

          <%!-- Funnel --%>
          <div class="bg-base-100 rounded-lg shadow p-6">
            <h2 class="text-lg font-semibold mb-4">{gettext("View → Application Funnel")}</h2>
            <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
              <div class="text-center p-4 bg-base-200 rounded-lg">
                <p class="text-xs uppercase tracking-wide text-base-content/50">{gettext("Views")}</p>
                <p class="text-2xl font-bold mt-1">{@funnel.total_views}</p>
              </div>
              <div class="flex items-center justify-center">
                <.icon name="hero-arrow-right" class="w-6 h-6 text-base-content/30" />
                <span class="ml-2 text-sm font-medium text-base-content/70">
                  {if @funnel.total_views > 0,
                    do: "#{@funnel.conversion_rate}% converted",
                    else: "0% conversion"}
                </span>
              </div>
              <div class="text-center p-4 bg-base-200 rounded-lg">
                <p class="text-xs uppercase tracking-wide text-base-content/50">
                  {gettext("Applications")}
                </p>
                <p class="text-2xl font-bold mt-1">{@funnel.total_applications}</p>
              </div>
            </div>
            <p
              :if={@funnel.tenant_avg_conversion_rate}
              class="mt-4 text-sm text-base-content/60 text-center"
            >
              Tenant average conversion: {@funnel.tenant_avg_conversion_rate}% across all jobs
            </p>
            <p
              :if={is_nil(@funnel.tenant_avg_conversion_rate)}
              class="mt-4 text-sm text-base-content/50 text-center"
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
