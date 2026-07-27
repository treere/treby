defmodule TrebyWeb.DashboardLive do
  use TrebyWeb, :live_view

  alias Treby.{Accounts, Tenants, Dashboard, Jobs, Candidates, Careers}

  def mount(_params, session, socket) do
    socket = set_locale_from_session(socket, session)
    user = Accounts.get_user!(session["user_id"])
    tenant = Tenants.get_tenant!(session["tenant_id"])
    data = Dashboard.get_dashboard_data(tenant.id, user.id)

    steps = onboarding_steps(tenant, user)
    all_done = Enum.all?(steps, & &1.done)

    {:ok,
     socket
     |> assign(current_user: user, current_tenant: tenant)
     |> assign(data)
     |> assign(
       onboarding_steps: steps,
       show_onboarding: !all_done && !user.onboarding_checklist_dismissed
     )}
  end

  def handle_event("dismiss-onboarding", %{"dismiss" => "permanent"}, socket) do
    {:ok, user} = Accounts.dismiss_onboarding_checklist(socket.assigns.current_user)
    {:noreply, assign(socket, current_user: user, show_onboarding: false)}
  end

  def handle_event("dismiss-onboarding", _, socket) do
    {:noreply, assign(socket, show_onboarding: false)}
  end

  defp onboarding_steps(tenant, user) do
    [
      %{
        id: :create_job,
        label: "Create a job posting",
        done: Jobs.tenant_has_jobs?(tenant.id),
        href: "/app/jobs"
      },
      %{
        id: :add_candidate,
        label: "Add your first candidate",
        done: Candidates.tenant_has_candidates?(tenant.id),
        href: "/app/candidates"
      },
      %{
        id: :invite_team,
        label: "Invite your team",
        done: Accounts.has_members_besides?(tenant.id, user.id),
        href: "/app/settings/team"
      },
      %{
        id: :brand_career,
        label: "Customize your career page",
        done: Careers.has_branding?(tenant.id),
        href: "/app/settings/branding"
      }
    ]
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_user} locale={@locale}>
      <div class="p-8 max-w-7xl mx-auto">
        <h1 class="text-2xl font-bold mb-2">Dashboard</h1>
        <p class="text-gray-600 mb-8">Welcome, {@current_user.name}!</p>

        <.onboarding_checklist
          steps={@onboarding_steps}
          current_user={@current_user}
          show={@show_onboarding}
        />

        <%!-- Weekly Stats --%>
        <div class="grid grid-cols-4 gap-4 mb-8">
          <div class="bg-white rounded-lg shadow p-4">
            <p class="text-sm text-gray-500">Applications This Week</p>
            <p class="text-3xl font-bold text-blue-600">{@weekly_stats.applications}</p>
          </div>
          <div class="bg-white rounded-lg shadow p-4">
            <p class="text-sm text-gray-500">Interviews This Week</p>
            <p class="text-3xl font-bold text-purple-600">{@weekly_stats.interviews}</p>
          </div>
          <div class="bg-white rounded-lg shadow p-4">
            <p class="text-sm text-gray-500">Offers This Week</p>
            <p class="text-3xl font-bold text-pink-600">{@weekly_stats.offers}</p>
          </div>
          <div class="bg-white rounded-lg shadow p-4">
            <p class="text-sm text-gray-500">Hires This Week</p>
            <p class="text-3xl font-bold text-green-600">{@weekly_stats.hires}</p>
          </div>
        </div>

        <div class="grid grid-cols-2 gap-8">
          <%!-- Upcoming Interviews --%>
          <div class="bg-white rounded-lg shadow p-6">
            <h2 class="text-lg font-semibold mb-4">Upcoming Interviews (7 days)</h2>
            <.empty_state
              :if={@upcoming_interviews == []}
              icon="hero-calendar"
              title="No upcoming interviews"
              description="Interviews you schedule will appear here. Create a job and move candidates through your pipeline to get started."
            />
            <div :for={interview <- @upcoming_interviews} class="border-b last:border-0 py-3">
              <div class="flex justify-between items-start">
                <div>
                  <p class="font-medium text-gray-900">
                    {interview.application.candidate.name}
                  </p>
                  <p class="text-sm text-gray-500">
                    {interview.application.job.title}
                  </p>
                </div>
                <div class="text-right text-sm">
                  <p class="text-gray-700">
                    {Elixir.Calendar.strftime(interview.start_at_utc, "%b %d")}
                  </p>
                  <p class="text-gray-500">
                    {Elixir.Calendar.strftime(interview.start_at_utc, "%H:%M")} - {Elixir.Calendar.strftime(
                      interview.end_at_utc,
                      "%H:%M"
                    )}
                  </p>
                </div>
              </div>
              <p class="text-xs text-gray-400 mt-1">
                with {interview.interviewer.name}
              </p>
            </div>
          </div>

          <%!-- Stale Candidates --%>
          <div class="bg-white rounded-lg shadow p-6">
            <h2 class="text-lg font-semibold mb-4">Stale Candidates (7+ days)</h2>
            <.empty_state
              :if={@stale_candidates == []}
              icon="hero-user-group"
              title="No stale candidates"
              description="Candidates with no recent activity will show here. Add candidates and move them through your pipeline to track engagement."
            />
            <div :for={app <- @stale_candidates} class="border-b last:border-0 py-3">
              <div class="flex justify-between items-center">
                <div>
                  <p class="font-medium text-gray-900">{app.candidate.name}</p>
                  <p class="text-sm text-gray-500">{app.job.title}</p>
                </div>
                <div class="text-right">
                  <span class="text-xs bg-yellow-100 text-yellow-800 px-2 py-1 rounded">
                    {app.pipeline_stage.name}
                  </span>
                  <p class="text-xs text-gray-400 mt-1">
                    Updated {Calendar.strftime(app.updated_at, "%b %d")}
                  </p>
                </div>
              </div>
            </div>
          </div>
        </div>

        <%!-- Pipeline Snapshot --%>
        <div class="mt-8 bg-white rounded-lg shadow p-6">
          <h2 class="text-lg font-semibold mb-4">Pipeline Overview</h2>
          <.empty_state
            :if={@pipeline_snapshot == []}
            icon="hero-kanban"
            title="No open jobs yet"
            description="Job postings let candidates apply through your career page and help you track applicants through each stage."
            action={%{href: "/app/jobs", label: "Create your first job"}}
          />
          <div :for={job_data <- @pipeline_snapshot} class="mb-6 last:mb-0">
            <h3 class="font-medium text-gray-800 mb-2">{job_data.job.title}</h3>
            <div class="flex gap-2 items-end h-24">
              <div
                :for={stage <- job_data.stages}
                class="flex flex-col items-center flex-1"
              >
                <span class="text-xs text-gray-600 mb-1">{stage.count}</span>
                <div
                  class="w-full rounded-t"
                  style={
                    "background-color: #{stage.stage.color}; height: #{max(stage.count * 8, 4)}px"
                  }
                >
                </div>
                <span class="text-xs text-gray-500 mt-1 truncate w-full text-center">
                  {stage.stage.name}
                </span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
