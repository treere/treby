defmodule TrebyWeb.DashboardLive do
  use TrebyWeb, :live_view

  import TrebyWeb.ScorecardForm, only: [scorecard_form: 1]

  alias Treby.{Accounts, Tenants, Dashboard, Jobs, Candidates, Careers, Scorecards}

  def mount(_params, session, socket) do
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

    data = Dashboard.get_dashboard_data(tenant.id, user.id)

    steps = onboarding_steps(tenant, user)
    all_done = Enum.all?(steps, & &1.done)

    recent_activities = Treby.Activities.list_events_for_tenant(tenant.id)

    {:ok,
     socket
     |> assign(current_user: user, current_tenant: tenant)
     |> assign(data)
     |> assign(recent_activities: recent_activities)
     |> assign(
       onboarding_steps: steps,
       show_onboarding: !all_done && !user.onboarding_checklist_dismissed
     )
     |> assign(show_scorecard_form: false, scorecard_event_id: nil, scorecard_form: to_form(%{}))
     |> assign(scorecard_criteria: [])}
  end

  def handle_event("dismiss-onboarding", %{"dismiss" => "permanent"}, socket) do
    {:ok, user} = Accounts.dismiss_onboarding_checklist(socket.assigns.current_user)
    {:noreply, assign(socket, current_user: user, show_onboarding: false)}
  end

  def handle_event("dismiss-onboarding", _, socket) do
    {:noreply, assign(socket, show_onboarding: false)}
  end

  def handle_event("open_scorecard", %{"event_id" => event_id}, socket) do
    template = Scorecards.get_active_template(socket.assigns.current_tenant.id)

    existing_scorecard =
      Scorecards.get_scorecard_for_interview(event_id, socket.assigns.current_user.id)

    criteria = (template && template.criteria) || []

    scores = (existing_scorecard && existing_scorecard.scores) || %{}

    form_data = %{
      "recommendation" => (existing_scorecard && existing_scorecard.recommendation) || "",
      "notes" => (existing_scorecard && existing_scorecard.notes) || ""
    }

    form_data =
      Enum.reduce(criteria, form_data, fn c, acc ->
        key = c["name"]
        Map.put(acc, key, scores[key] || "")
      end)

    {:noreply,
     socket
     |> assign(show_scorecard_form: true, scorecard_event_id: event_id)
     |> assign(scorecard_template: template)
     |> assign(scorecard_criteria: criteria)
     |> assign(scorecard_form: to_form(form_data))}
  end

  def handle_event("close_scorecard", _, socket) do
    {:noreply,
     socket
     |> assign(show_scorecard_form: false, scorecard_event_id: nil)}
  end

  def handle_event("submit_scorecard", params, socket) do
    event_id = socket.assigns.scorecard_event_id
    criteria = socket.assigns.scorecard_criteria

    scores =
      criteria
      |> Enum.map(fn c -> {c["name"], Map.get(params, c["name"], "")} end)
      |> Map.new()

    attrs = %{
      "scores" => scores,
      "recommendation" => Map.get(params, "recommendation", ""),
      "notes" => Map.get(params, "notes", ""),
      "tenant_id" => socket.assigns.current_tenant.id
    }

    case Scorecards.submit_scorecard(event_id, socket.assigns.current_user.id, attrs) do
      {:ok, _scorecard} ->
        data =
          Dashboard.get_dashboard_data(
            socket.assigns.current_tenant.id,
            socket.assigns.current_user.id
          )

        {:noreply,
         socket
         |> assign(data)
         |> assign(show_scorecard_form: false, scorecard_event_id: nil)
         |> put_flash(:info, gettext("Scorecard submitted"))}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, gettext("Failed to submit scorecard"))}
    end
  end

  defp onboarding_steps(tenant, user) do
    [
      %{
        id: :create_job,
        label: gettext("Create a job posting"),
        done: Jobs.tenant_has_jobs?(tenant.id),
        href: "/app/jobs"
      },
      %{
        id: :add_candidate,
        label: gettext("Add your first candidate"),
        done: Candidates.tenant_has_candidates?(tenant.id),
        href: "/app/candidates"
      },
      %{
        id: :invite_team,
        label: gettext("Invite your team"),
        done: Accounts.has_members_besides?(tenant.id, user.id),
        href: "/app/settings/team"
      },
      %{
        id: :brand_career,
        label: gettext("Customize your career page"),
        done: Careers.has_branding?(tenant.id),
        href: "/app/settings/branding"
      }
    ]
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_user} locale={@locale}>
      <div class="p-8 max-w-7xl mx-auto">
        <.page_header
          title={gettext("Dashboard")}
          subtitle={gettext("Welcome, %{name}!", name: @current_user.name)}
        />

        <.onboarding_checklist
          steps={@onboarding_steps}
          current_user={@current_user}
          show={@show_onboarding}
        />

        <%!-- Weekly Stats --%>
        <div class="grid grid-cols-4 gap-4 mb-8">
          <.card class="shadow">
            <p class="text-sm text-zinc-400 dark:text-zinc-500">
              {gettext("Applications This Week")}
            </p>
            <p class="text-3xl font-bold text-blue-600">{@weekly_stats.applications}</p>
          </.card>
          <.card class="shadow">
            <p class="text-sm text-zinc-400 dark:text-zinc-500">{gettext("Interviews This Week")}</p>
            <p class="text-3xl font-bold text-purple-600">{@weekly_stats.interviews}</p>
          </.card>
          <.card class="shadow">
            <p class="text-sm text-zinc-400 dark:text-zinc-500">{gettext("Offers This Week")}</p>
            <p class="text-3xl font-bold text-pink-600">{@weekly_stats.offers}</p>
          </.card>
          <.card class="shadow">
            <p class="text-sm text-zinc-400 dark:text-zinc-500">{gettext("Hires This Week")}</p>
            <p class="text-3xl font-bold text-green-600">{@weekly_stats.hires}</p>
          </.card>
        </div>

        <%!-- My Actions --%>
        <.card class="shadow mb-8">
          <h2 class="text-lg font-semibold mb-4">{gettext("My Actions")}</h2>

          <%!-- Pending scorecards --%>
          <%= if @my_actions.pending_scorecards == [] and @my_actions.waiting_on_others == [] do %>
            <.empty_state
              icon="hero-check-circle"
              title={gettext("All caught up")}
              description={
                gettext(
                  "You have no outstanding scorecards right now. Anything you need to do will appear here."
                )
              }
            />
          <% else %>
            <%= if @my_actions.pending_scorecards != [] do %>
              <h3 class="text-sm font-medium text-zinc-500 dark:text-zinc-400 mb-2">
                {gettext("Scorecards to fill")}
              </h3>
              <div class="space-y-2 mb-4">
                <div
                  :for={action <- @my_actions.pending_scorecards}
                  class="flex items-center justify-between gap-3 border border-zinc-200 dark:border-zinc-700 rounded-lg px-4 py-3"
                >
                  <div>
                    <p class="font-medium text-zinc-900 dark:text-zinc-100">
                      {action.candidate_name}
                    </p>
                    <p class="text-sm text-zinc-400 dark:text-zinc-500">{action.job_title}</p>
                    <p class="text-xs text-zinc-400 dark:text-zinc-500">
                      {gettext("Interview %{date}",
                        date: Elixir.Calendar.strftime(action.start_at, "%b %d at %H:%M")
                      )}
                    </p>
                  </div>
                  <.button
                    variant="primary"
                    size="sm"
                    phx-click="open_scorecard"
                    phx-value-event_id={action.event_id}
                  >
                    {gettext("Fill scorecard")}
                  </.button>
                </div>
              </div>
            <% end %>

            <%= if @my_actions.waiting_on_others != [] do %>
              <h3 class="text-sm font-medium text-zinc-500 dark:text-zinc-400 mb-2">
                {gettext("Waiting on others")}
              </h3>
              <div class="space-y-2">
                <div
                  :for={waiting <- @my_actions.waiting_on_others}
                  class="border border-zinc-200 dark:border-zinc-700 rounded-lg px-4 py-3"
                >
                  <p class="font-medium text-zinc-900 dark:text-zinc-100">{waiting.candidate_name}</p>
                  <p class="text-sm text-zinc-400 dark:text-zinc-500">{waiting.job_title}</p>
                  <ul class="mt-1 space-y-0.5">
                    <li
                      :for={blocker <- waiting.blockers}
                      class="text-xs text-amber-700 dark:text-amber-300"
                    >
                      {blocker}
                    </li>
                  </ul>
                </div>
              </div>
            <% end %>
          <% end %>
        </.card>

        <div class="grid grid-cols-2 gap-8">
          <%!-- Upcoming Interviews --%>
          <.card class="shadow">
            <h2 class="text-lg font-semibold mb-4">{gettext("Upcoming Interviews (7 days)")}</h2>
            <.empty_state
              :if={@upcoming_interviews == []}
              icon="hero-calendar"
              title={gettext("No upcoming interviews")}
              description={
                gettext(
                  "Interviews you schedule will appear here. Create a job and move candidates through your pipeline to get started."
                )
              }
            />
            <div :for={interview <- @upcoming_interviews} class="border-b last:border-0 py-3">
              <div class="flex justify-between items-start">
                <div>
                  <p class="font-medium text-zinc-900 dark:text-zinc-100">
                    {interview.application.candidate.name}
                  </p>
                  <p class="text-sm text-zinc-400 dark:text-zinc-500">
                    {interview.application.job.title}
                  </p>
                </div>
                <div class="text-right text-sm">
                  <p class="text-zinc-900 dark:text-zinc-100/80">
                    {Elixir.Calendar.strftime(interview.start_at_utc, "%b %d")}
                  </p>
                  <p class="text-zinc-400 dark:text-zinc-500">
                    {Elixir.Calendar.strftime(interview.start_at_utc, "%H:%M")} - {Elixir.Calendar.strftime(
                      interview.end_at_utc,
                      "%H:%M"
                    )}
                  </p>
                </div>
              </div>
              <p class="text-xs text-zinc-400 dark:text-zinc-500 mt-1">
                {gettext("with %{name}", name: interviewer_name(interview))}
              </p>
            </div>
          </.card>

          <%!-- Stale Candidates --%>
          <.card class="shadow">
            <h2 class="text-lg font-semibold mb-4">{gettext("Stale Candidates (7+ days)")}</h2>
            <.empty_state
              :if={@stale_candidates == []}
              icon="hero-user-group"
              title={gettext("No stale candidates")}
              description={
                gettext(
                  "Candidates with no recent activity will show here. Add candidates and move them through your pipeline to track engagement."
                )
              }
            />
            <div :for={app <- @stale_candidates} class="border-b last:border-0 py-3">
              <div class="flex justify-between items-center">
                <div>
                  <p class="font-medium text-zinc-900 dark:text-zinc-100">{app.candidate.name}</p>
                  <p class="text-sm text-zinc-400 dark:text-zinc-500">{app.job.title}</p>
                </div>
                <div class="text-right">
                  <.badge variant="warning">{app.pipeline_stage.name}</.badge>
                  <p class="text-xs text-zinc-400 dark:text-zinc-500 mt-1">
                    {gettext("Updated %{date}", date: Calendar.strftime(app.updated_at, "%b %d"))}
                  </p>
                </div>
              </div>
            </div>
          </.card>
        </div>

        <%!-- Pipeline Snapshot --%>
        <.card class="shadow mt-8">
          <h2 class="text-lg font-semibold mb-4">{gettext("Pipeline Overview")}</h2>
          <.empty_state
            :if={@pipeline_snapshot == []}
            icon="hero-kanban"
            title={gettext("No open jobs yet")}
            description={
              gettext(
                "Job postings let candidates apply through your career page and help you track applicants through each stage."
              )
            }
            action={%{href: "/app/jobs", label: gettext("Create your first job")}}
          />
          <div :for={job_data <- @pipeline_snapshot} class="mb-6 last:mb-0">
            <h3 class="font-medium text-zinc-900 dark:text-zinc-100/90 mb-2">{job_data.job.title}</h3>
            <div class="flex gap-2 items-end h-24">
              <div
                :for={stage <- job_data.stages}
                class="flex flex-col items-center flex-1"
              >
                <span class="text-xs text-zinc-500 dark:text-zinc-400 mb-1">{stage.count}</span>
                <div
                  class="w-full rounded-t"
                  style={
                    "background-color: #{stage.stage.color}; height: #{max(stage.count * 8, 4)}px"
                  }
                >
                </div>
                <span class="text-xs text-zinc-400 dark:text-zinc-500 mt-1 truncate w-full text-center">
                  {stage.stage.name}
                </span>
              </div>
            </div>
          </div>
        </.card>
        <%!-- Recent Activity --%>
        <.card class="shadow mt-8">
          <h2 class="text-lg font-semibold mb-4">{gettext("Recent Activity")}</h2>
          <.empty_state
            :if={@recent_activities == []}
            icon="hero-clock"
            title={gettext("No activity yet")}
            description={gettext("Activity for your workspace will appear here.")}
          />
          <ul :if={@recent_activities != []} class="space-y-3">
            <li :for={activity <- @recent_activities} class="flex items-start gap-3 text-sm">
              <span class="mt-1.5 h-2 w-2 rounded-full bg-blue-500 flex-shrink-0"></span>
              <div>
                <span class="font-medium text-zinc-900 dark:text-zinc-100">{activity_label(activity)}</span>
                <span class="text-zinc-400 dark:text-zinc-500">
                  {activity.metadata && activity.metadata["candidate_name"]}
                </span>
                <div class="text-xs text-zinc-400 dark:text-zinc-500">
                  {Calendar.strftime(activity.inserted_at, "%b %d, %Y at %H:%M")}
                </div>
              </div>
            </li>
          </ul>
        </.card>
      </div>
      <.scorecard_form
        show={@show_scorecard_form}
        criteria={@scorecard_criteria}
        form={@scorecard_form}
      />
    </Layouts.app>
    """
  end

  defp activity_label(%{action: "new_application"}), do: gettext("New application")
  defp activity_label(%{action: "interview_scheduled"}), do: gettext("Interview scheduled")
  defp activity_label(%{action: "application_stage_changed"}), do: gettext("Stage change")
  defp activity_label(%{action: "candidates_merged"}), do: gettext("Candidates merged")
  defp activity_label(%{action: "candidate_created"}), do: gettext("Candidate created")

  defp activity_label(activity),
    do: activity.action |> String.replace("_", " ") |> String.capitalize()

  defp interviewer_name(%{event_examiners: [%{user: user} | _]}) when not is_nil(user) do
    user.name
  end

  defp interviewer_name(_), do: gettext("To be determined")
end
