defmodule TrebyWeb.CandidatesLive.Show do
  use TrebyWeb, :live_view

  import TrebyWeb.ScorecardForm, only: [scorecard_form: 1]

  alias Treby.{
    Accounts,
    Tenants,
    Candidates,
    Pipeline,
    Notes,
    Customization,
    Activities,
    Scorecards,
    CandidatePortal
  }

  alias Treby.Notifications.Email, as: NotificationEmail

  def mount(%{"id" => id} = params, session, socket) do
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

    candidate = Candidates.get_candidate(tenant.id, id)

    return_path = safe_return_path(params["return_to"])
    return_label = return_label(return_path)

    if is_nil(candidate) do
      {:ok, redirect(socket, to: ~p"/404")}
    else
      if candidate.merged_into_id do
        primary_id = candidate.merged_into_id

        {:ok,
         socket
         |> assign(current_user: user, current_tenant: tenant)
         |> put_flash(:info, gettext("This candidate was merged into another profile."))
         |> push_navigate(to: merged_redirect(primary_id, return_path))}
      else
        mount_active(socket, candidate, tenant, user, return_path, return_label)
      end
    end
  end

  defp mount_active(socket, candidate, tenant, user, return_path, return_label) do
    applications = Pipeline.list_applications_for_candidate(tenant.id, candidate.id)

    applications_with_notes =
      Enum.map(applications, fn app ->
        notes = Notes.list_notes_for_application(app.id)
        Map.put(app, :notes, notes)
      end)

    candidate_fields = Customization.list_custom_fields_for(tenant.id, "candidate")
    application_fields = Customization.list_custom_fields_for(tenant.id, "application")

    # Load all interviews for this candidate's applications
    application_ids = Enum.map(applications, & &1.id)

    interviews =
      if application_ids != [] do
        import Ecto.Query

        Treby.Interviews.InterviewEvent
        |> where([e], e.application_id in ^application_ids)
        |> order_by([e], desc: e.start_at_utc)
        |> preload(application: :job, event_examiners: :user)
        |> Treby.Repo.all()
      else
        []
      end

    # Load scorecards for this candidate
    scorecards = Scorecards.list_scorecards_for_candidate(candidate.id)
    aggregate_scores = Scorecards.compute_aggregate_scores(candidate.id)

    # Load activity timeline
    activities = Activities.list_events_for_entity("candidate", candidate.id, 20)

    # Load merge history where this candidate was the surviving primary
    merge_logs = Candidates.list_merge_logs_for_primary(candidate.id)

    # Load conversations for the candidate
    conversations = CandidatePortal.list_conversations_for_candidate(candidate.id, tenant.id)

    Enum.each(conversations, &CandidatePortal.subscribe_to_conversation(&1.id))

    {:ok,
     socket
     |> assign(current_user: user, current_tenant: tenant)
     |> assign(return_path: return_path, return_label: return_label)
     |> assign(candidate: candidate)
     |> assign(applications: applications_with_notes)
     |> assign(candidate_fields: candidate_fields)
     |> assign(application_fields: application_fields)
     |> assign(interviews: interviews)
     |> assign(scorecards: scorecards)
     |> assign(aggregate_scores: aggregate_scores)
     |> assign(activities: activities)
     |> assign(merge_logs: merge_logs)
     |> assign(conversations: conversations)
     |> assign(show_note_form: nil)
     |> assign(note_form: to_form(%{}, as: :note))
     |> assign(editing?: false)
     |> assign(edit_form: to_form(Candidates.change_candidate(candidate)))
     |> assign(confirm_delete: nil)
     |> assign(new_message_form_visible: false)
     |> assign(new_message_form: to_form(%{}, as: :message))
     |> assign(replying_to_conversation: nil)
     |> assign(conversation_reply_form: to_form(%{}, as: :reply))
     |> assign(show_request_info_form: false)
     |> assign(request_info_form: to_form(%{}, as: :request_info))
     |> assign(show_reject_form: false)
     |> assign(reject_form: to_form(%{}, as: :reject))
     |> assign(completing_interview: nil)
     |> assign(show_scorecard_form: false)
     |> assign(scorecard_event_id: nil)
     |> assign(scorecard_criteria: [])
     |> assign(scorecard_template: nil)
     |> assign(scorecard_form: to_form(%{}))}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_user} locale={@locale}>
      <div class="p-8">
        <.link navigate={@return_path} class="text-blue-600 hover:text-blue-900 text-sm">
          &larr; Back to {@return_label}
        </.link>

        <div class="mt-6 bg-white dark:bg-zinc-800 rounded-xl border border-zinc-200 dark:border-zinc-700 shadow-sm p-8">
          <%= if @editing? do %>
            <h2 class="text-lg font-semibold mb-4">{gettext("Edit Candidate")}</h2>
            <.form
              for={@edit_form}
              id="edit-candidate-form"
              phx-submit="save_edit"
              class="space-y-4"
            >
              <.input field={@edit_form[:name]} type="text" label={gettext("Name")} />
              <.input field={@edit_form[:email]} type="email" label={gettext("Email")} />
              <.input field={@edit_form[:phone]} type="text" label={gettext("Phone")} />
              <.input field={@edit_form[:linkedin_url]} type="url" label={gettext("LinkedIn URL")} />

              <div :if={@candidate_fields != []} class="border-t pt-4">
                <h3 class="text-sm font-medium text-zinc-900 dark:text-zinc-100/80 mb-3">
                  {gettext("Custom Fields")}
                </h3>
                <div :for={field <- @candidate_fields} class="mb-3">
                  <%= cond do %>
                    <% field.field_type == "select" -> %>
                      <.input
                        name={"custom_fields[#{field.id}]"}
                        type="select"
                        label={field.name}
                        value={Map.get(@candidate.custom_fields || %{}, field.id)}
                        options={field.options}
                        prompt="—"
                      />
                    <% field.field_type == "date" -> %>
                      <.input
                        name={"custom_fields[#{field.id}]"}
                        type="date"
                        label={field.name}
                        value={Map.get(@candidate.custom_fields || %{}, field.id, "")}
                      />
                    <% field.field_type == "number" -> %>
                      <.input
                        name={"custom_fields[#{field.id}]"}
                        type="number"
                        label={field.name}
                        value={Map.get(@candidate.custom_fields || %{}, field.id, "")}
                      />
                    <% field.field_type == "url" -> %>
                      <.input
                        name={"custom_fields[#{field.id}]"}
                        type="url"
                        label={field.name}
                        value={Map.get(@candidate.custom_fields || %{}, field.id, "")}
                      />
                    <% true -> %>
                      <.input
                        name={"custom_fields[#{field.id}]"}
                        type="text"
                        label={field.name}
                        value={Map.get(@candidate.custom_fields || %{}, field.id, "")}
                      />
                  <% end %>
                </div>
              </div>

              <div class="flex gap-2">
                <.button type="submit" variant="primary">{gettext("Save")}</.button>
                <.button type="button" phx-click="cancel_edit" variant="ghost">
                  Cancel
                </.button>
              </div>
            </.form>
          <% else %>
            <div class="flex justify-between items-start">
              <div>
                <h1 class="text-2xl font-bold text-zinc-900 dark:text-zinc-100">{@candidate.name}</h1>
                <p class="text-zinc-500 dark:text-zinc-400">{@candidate.email}</p>
                <p :if={@candidate.phone} class="text-zinc-500 dark:text-zinc-400">
                  {@candidate.phone}
                </p>
                <p :if={@candidate.linkedin_url} class="mt-2">
                  <.link
                    href={@candidate.linkedin_url}
                    target="_blank"
                    class="text-blue-600 hover:text-blue-900"
                  >
                    LinkedIn Profile
                  </.link>
                </p>
              </div>
              <.button phx-click="start_edit" variant="ghost" size="sm">
                Edit
              </.button>
            </div>

            <div
              :if={@merge_logs != []}
              class="mt-4 bg-blue-50 dark:bg-blue-950 border border-blue-200 dark:border-blue-900 rounded-lg p-4"
            >
              <div class="flex items-center gap-2 mb-2">
                <.icon name="hero-user-group" class="w-4 h-4 text-blue-700" />
                <h3 class="text-sm font-semibold text-blue-900">
                  This profile absorbed {length(@merge_logs)} duplicate {if(length(@merge_logs) == 1,
                    do: "profile",
                    else: "profiles"
                  )}
                </h3>
              </div>
              <div :for={log <- @merge_logs} class="flex items-center justify-between gap-3 mt-2">
                <p class="text-xs text-blue-800">
                  Merged <span class="font-medium">{log.absorbed_candidate.name}</span>
                  on {Calendar.strftime(log.merged_at, "%b %d, %Y")}
                </p>
                <.button
                  phx-click="undo_merge"
                  phx-value-merge_id={log.id}
                  variant="ghost"
                  size="sm"
                >
                  Undo merge
                </.button>
              </div>
            </div>

            <div :if={@candidate_fields != []} class="mt-6 border-t pt-4">
              <h3 class="text-sm font-medium text-zinc-900 dark:text-zinc-100/80 mb-2">
                {gettext("Custom Fields")}
              </h3>
              <dl class="grid grid-cols-2 gap-x-4 gap-y-2">
                <div :for={field <- @candidate_fields}>
                  <dt class="text-sm text-zinc-400 dark:text-zinc-500">{field.name}</dt>
                  <dd class="text-sm text-zinc-900 dark:text-zinc-100">
                    {Map.get(@candidate.custom_fields || %{}, field.id, "—")}
                  </dd>
                </div>
              </dl>
            </div>
          <% end %>
        </div>

        <%= if @applications != [] do %>
          <% primary = hd(@applications) %>
          <% state = Treby.Pipeline.current_state(primary) %>
          <div class="mt-8">
            <h2 class="text-xl font-semibold text-zinc-900 dark:text-zinc-100/90 mb-4">
              {gettext("Progress")}
            </h2>
            <div class="bg-white dark:bg-zinc-800 rounded-xl border border-zinc-200 dark:border-zinc-700 shadow-sm p-4">
              <div class="flex items-center gap-2 mb-3">
                <.icon name="hero-flag" class="w-4 h-4 text-zinc-500 dark:text-zinc-400" />
                <span class="text-sm text-zinc-500 dark:text-zinc-400">
                  Current stage:
                </span>
                <span class="px-2 py-1 text-xs rounded-full bg-blue-100 text-blue-800">
                  {state.stage.name}
                </span>
              </div>

              <%= if state.blocked? do %>
                <div class="space-y-1 mb-3">
                  <%= for blocker <- state.blockers do %>
                    <div class="flex items-center gap-1 text-xs text-amber-700 dark:text-amber-300 bg-amber-50 dark:bg-amber-950 rounded px-2 py-1">
                      <.icon name="hero-exclamation-triangle" class="w-3 h-3" />
                      <span>{blocker.label}</span>
                    </div>
                  <% end %>
                </div>
              <% else %>
                <p class="text-sm text-green-700 bg-green-50 dark:bg-green-950 rounded px-2 py-1 mb-3">
                  <.icon name="hero-check-circle" class="w-4 h-4 inline" /> No blockers — on track.
                </p>
              <% end %>

              <%= if state.next_actions != [] do %>
                <div class="space-y-1">
                  <p class="text-xs font-medium text-zinc-500 dark:text-zinc-400 uppercase tracking-wide">
                    Next steps
                  </p>
                  <%= for action <- state.next_actions do %>
                    <div class="flex items-center gap-2 text-sm">
                      <.icon name="hero-arrow-right" class="w-3 h-3 text-zinc-400 dark:text-zinc-500" />
                      <span>{action.label}</span>
                      <%= if action.assignee do %>
                        <span class="text-xs text-zinc-400 dark:text-zinc-500">— {action.assignee.name}</span>
                      <% end %>
                    </div>
                  <% end %>
                </div>
              <% end %>
            </div>
          </div>
        <% end %>

        <%= if @interviews != [] do %>
          <div class="mt-8">
            <h2 class="text-xl font-semibold text-zinc-900 dark:text-zinc-100/90 mb-4">
              {gettext("Scheduled Interviews")}
            </h2>
            <div class="space-y-3">
              <%= for interview <- @interviews do %>
                <div class={[
                  "bg-white dark:bg-zinc-800 rounded-xl border border-zinc-200 dark:border-zinc-700 shadow-sm p-4",
                  interview.status == "cancelled" && "opacity-60"
                ]}>
                  <div class="flex items-start justify-between">
                    <div>
                      <p class={[
                        "font-medium text-zinc-900 dark:text-zinc-100",
                        interview.status == "cancelled" && "line-through"
                      ]}>
                        {interview.application.job.title}
                      </p>
                      <div class={[
                        "flex items-center gap-4 mt-1 text-sm",
                        interview.status == "cancelled" && "line-through",
                        interview.status == "cancelled" && "text-zinc-400 dark:text-zinc-500",
                        interview.status != "cancelled" && "text-zinc-400 dark:text-zinc-500"
                      ]}>
                        <span class="flex items-center gap-1">
                          <.icon name="hero-calendar" class="w-4 h-4" />
                          {Elixir.Calendar.strftime(interview.start_at_utc, "%B %d, %Y")}
                        </span>
                        <span class="flex items-center gap-1">
                          <.icon name="hero-clock" class="w-4 h-4" />
                          {Elixir.Calendar.strftime(interview.start_at_utc, "%H:%M")} - {Elixir.Calendar.strftime(
                            interview.end_at_utc,
                            "%H:%M"
                          )}
                        </span>
                        <span class="flex items-center gap-1">
                          <.icon name="hero-user" class="w-4 h-4" />
                          {interview.event_examiners |> Enum.map(& &1.user.name) |> Enum.join(", ")}
                        </span>
                      </div>
                    </div>
                    <div class="flex items-center gap-2">
                      <.badge
                        variant={if interview.status == "scheduled", do: "success", else: "default"}
                        class="text-xs"
                      >
                        {interview.status}
                      </.badge>
                      <%= if interview.status == "scheduled" do %>
                        <.button
                          phx-click="complete_interview"
                          phx-value-id={interview.id}
                          variant="ghost"
                          size="sm"
                        >
                          Mark as completed
                        </.button>
                      <% end %>
                      <%= if Enum.any?(interview.event_examiners, &(&1.user_id == @current_user.id)) do %>
                        <.button
                          phx-click="open_scorecard"
                          phx-value-event_id={interview.id}
                          variant="ghost"
                          size="sm"
                        >
                          Scorecard
                        </.button>
                      <% end %>
                      <%= if interview.video_conf_url do %>
                        <a
                          href={interview.video_conf_url}
                          target="_blank"
                          class="px-3 py-1 text-sm bg-green-50 dark:bg-green-950 text-green-700 dark:text-green-100 rounded-md hover:bg-green-100"
                        >
                          Join Meet
                        </a>
                      <% end %>
                    </div>
                  </div>
                </div>
              <% end %>
            </div>
          </div>
        <% end %>

        <div class="mt-8">
          <h2 class="text-xl font-semibold text-zinc-900 dark:text-zinc-100/90 mb-4">
            {gettext("Applications")}
          </h2>
          <div :if={@applications == []} class="text-zinc-400 dark:text-zinc-500">
            No applications yet.
          </div>
          <div
            :for={application <- @applications}
            class="bg-white dark:bg-zinc-800 rounded-xl border border-zinc-200 dark:border-zinc-700 shadow-sm p-4 mb-4"
          >
            <div class="flex justify-between items-center">
              <div>
                <div class="flex items-center gap-2">
                  <.link
                    navigate={~p"/app/pipeline/#{application.job_id}"}
                    class="font-medium text-blue-600 hover:text-blue-900"
                  >
                    {application.job.title}
                  </.link>
                  <.badge :if={application.is_duplicate} variant="warning" class="text-xs">
                    DUPLICATE APP
                  </.badge>
                </div>
                <p class="text-sm text-zinc-400 dark:text-zinc-500">
                  Stage: {application.pipeline_stage.name}
                </p>
                <p :if={application.source} class="text-sm text-zinc-400 dark:text-zinc-500">
                  Source: {application.source}
                </p>
                <div
                  :if={
                    application.anagrafica && anagrafica_differs?(application.anagrafica, @candidate)
                  }
                  class="mt-2 text-xs bg-yellow-50 dark:bg-yellow-950 border border-yellow-200 dark:border-yellow-900 rounded p-2"
                >
                  <p class="font-medium text-yellow-900 mb-1">{gettext("As submitted")}</p>
                  <dl class="grid grid-cols-2 gap-x-3 gap-y-0.5 text-yellow-900">
                    <%= for {key, value} <- application.anagrafica do %>
                      <dt class="font-medium">{humanize_anagrafica_key(key)}</dt>
                      <dd>{value}</dd>
                    <% end %>
                  </dl>
                </div>
              </div>
              <div class="flex items-center gap-3">
                <a
                  :if={application.resume_url}
                  href={~p"/app/applications/#{application.id}/resume"}
                  class="text-sm text-blue-600 hover:text-blue-900"
                >
                  View Resume
                </a>
                <.link
                  navigate={~p"/app/schedule/#{application.id}"}
                  class="text-sm text-blue-600 hover:text-blue-900"
                >
                  Schedule Interview
                </.link>
                <span class="text-sm text-zinc-400 dark:text-zinc-500">
                  {Calendar.strftime(application.inserted_at, "%b %d, %Y")}
                </span>
                <.button
                  phx-click="toggle_note_form"
                  phx-value-application_id={application.id}
                  variant="ghost"
                  size="sm"
                >
                  Add Note
                </.button>
              </div>
            </div>

            <div :if={@application_fields != []} class="mt-3 border-t pt-3">
              <dl class="grid grid-cols-2 gap-x-4 gap-y-1">
                <div :for={field <- @application_fields}>
                  <dt class="text-xs text-zinc-400 dark:text-zinc-500">{field.name}</dt>
                  <dd class="text-xs text-zinc-900 dark:text-zinc-100">
                    {Map.get(application.custom_fields || %{}, field.id, "—")}
                  </dd>
                </div>
              </dl>
            </div>

            <%!-- Notes for this application --%>
            <div :if={application.notes != []} class="mt-4 border-t pt-4">
              <h3 class="text-sm font-medium text-zinc-900 dark:text-zinc-100/80 mb-2">
                {gettext("Notes")}
              </h3>
              <div :for={note <- application.notes} class="mb-3 last:mb-0">
                <div class="flex items-start gap-2">
                  <div class="flex-1">
                    <div class="flex items-center gap-2">
                      <span class="text-sm font-medium text-zinc-900 dark:text-zinc-100">{note.author.name}</span>
                      <span
                        :if={note.type == "interview_feedback"}
                        class="text-xs bg-blue-100 text-blue-800 px-1.5 py-0.5 rounded"
                      >
                        Interview Feedback
                      </span>
                      <span :if={note.rating} class="text-xs text-yellow-600">
                        {"★" <> to_string(note.rating) <> "/5"}
                      </span>
                      <span class="text-xs text-zinc-400 dark:text-zinc-500">
                        {Calendar.strftime(note.inserted_at, "%b %d, %Y at %H:%M")}
                      </span>
                    </div>
                    <p class="text-sm text-zinc-500 dark:text-zinc-400 mt-1">{note.content}</p>
                  </div>
                  <%= if note.author_id == @current_user.id do %>
                    <.button
                      phx-click="confirm_delete"
                      phx-value-id={note.id}
                      phx-value-title={gettext("Delete note")}
                      phx-value-message={
                        gettext(
                          "Are you sure you want to delete this note? This action cannot be undone."
                        )
                      }
                      variant="ghost"
                      size="sm"
                    >
                      Delete
                    </.button>
                  <% end %>
                </div>
              </div>
            </div>

            <%!-- Note form for this application --%>
            <div :if={@show_note_form == application.id} class="mt-4 border-t pt-4">
              <.form
                for={@note_form}
                id={"note-form-#{application.id}"}
                phx-submit="create_note"
                phx-value-application_id={application.id}
                class="space-y-3"
              >
                <.input
                  field={@note_form[:content]}
                  type="textarea"
                  label={gettext("Note")}
                  placeholder={gettext("Add your note...")}
                  rows={3}
                />
                <div class="flex gap-4">
                  <.input
                    field={@note_form[:type]}
                    type="select"
                    label={gettext("Type")}
                    options={[{"Note", "note"}, {gettext("Interview Feedback"), "interview_feedback"}]}
                  />
                  <.input
                    field={@note_form[:rating]}
                    type="select"
                    label={gettext("Rating")}
                    options={[
                      {"", ""},
                      {"1 - Poor", 1},
                      {"2 - Fair", 2},
                      {"3 - Good", 3},
                      {"4 - Very Good", 4},
                      {"5 - Excellent", 5}
                    ]}
                  />
                </div>
                <div class="flex gap-2">
                  <.button type="submit" variant="primary" size="sm">{gettext("Save Note")}</.button>
                  <.button
                    type="button"
                    phx-click="toggle_note_form"
                    phx-value-application_id=""
                    variant="ghost"
                    size="sm"
                  >
                    Cancel
                  </.button>
                </div>
              </.form>
            </div>
          </div>
        </div>

        <%!-- Activity Timeline --%>
        <div class="mt-8 bg-white dark:bg-zinc-800 rounded-xl border border-zinc-200 dark:border-zinc-700 shadow-sm p-6">
          <h2 class="text-lg font-semibold mb-4">{gettext("Activity")}</h2>
          <.activity_timeline events={@activities} />
        </div>

        <%!-- Scorecards --%>
        <div
          :if={@scorecards != [] || @aggregate_scores.total_scorecards > 0}
          class="mt-8 bg-white dark:bg-zinc-800 rounded-xl border border-zinc-200 dark:border-zinc-700 shadow-sm p-6"
        >
          <h2 class="text-lg font-semibold mb-4">{gettext("Scorecards")}</h2>

          <%!-- Aggregate View --%>
          <div
            :if={@aggregate_scores.total_scorecards > 0}
            class="mb-6 p-4 bg-zinc-50 dark:bg-zinc-800 rounded-lg"
          >
            <h3 class="text-sm font-medium text-zinc-900 dark:text-zinc-100/80 mb-3">
              Aggregate ({@aggregate_scores.total_scorecards} scorecard{@aggregate_scores.total_scorecards >
                1 && "s"})
            </h3>

            <div :if={@aggregate_scores.avg_scores != %{}} class="mb-4">
              <h4 class="text-xs font-medium text-zinc-400 dark:text-zinc-500 uppercase mb-2">
                {gettext("Average Scores")}
              </h4>
              <div class="grid grid-cols-2 gap-2">
                <div
                  :for={{criterion, avg} <- @aggregate_scores.avg_scores}
                  class="flex justify-between text-sm"
                >
                  <span class="text-zinc-500 dark:text-zinc-400">{criterion}</span>
                  <span class="font-medium text-zinc-900 dark:text-zinc-100">{Float.round(avg, 1)}</span>
                </div>
              </div>
            </div>

            <div :if={@aggregate_scores.recommendation_counts != %{}}>
              <h4 class="text-xs font-medium text-zinc-400 dark:text-zinc-500 uppercase mb-2">
                {gettext("Recommendations")}
              </h4>
              <div class="flex gap-3">
                <div :for={{rec, count} <- @aggregate_scores.recommendation_counts} class="text-sm">
                  <span class="text-zinc-500 dark:text-zinc-400">
                    {String.capitalize(rec |> String.replace("_", " "))}
                  </span>
                  <span class="font-medium text-zinc-900 dark:text-zinc-100 ml-1">({count})</span>
                </div>
              </div>
            </div>
          </div>

          <%!-- Individual Scorecards --%>
          <div class="space-y-4">
            <div :for={scorecard <- @scorecards} class="border rounded-lg p-4">
              <div class="flex justify-between items-start mb-2">
                <div>
                  <span class="font-medium text-zinc-900 dark:text-zinc-100">{scorecard.interviewer.name}</span>
                  <span class="text-sm text-zinc-400 dark:text-zinc-500 ml-2">
                    {Calendar.strftime(scorecard.inserted_at, "%b %d, %Y")}
                  </span>
                </div>
                <span
                  :if={scorecard.recommendation}
                  class={[
                    "px-2 py-1 text-xs rounded-full",
                    case scorecard.recommendation do
                      "hire" -> "bg-green-100 text-green-800"
                      "lean_hire" -> "bg-blue-100 text-blue-800"
                      "lean_no_hire" -> "bg-yellow-100 text-yellow-800"
                      "no_hire" -> "bg-orange-100 text-orange-800"
                      "strong_no_hire" -> "bg-red-100 text-red-800"
                      _ -> "bg-zinc-50 dark:bg-zinc-800 text-zinc-900 dark:text-zinc-100/90"
                    end
                  ]}
                >
                  {scorecard.recommendation |> String.replace("_", " ") |> String.capitalize()}
                </span>
              </div>

              <div :if={scorecard.scores != %{}} class="grid grid-cols-2 gap-2 mb-3">
                <div
                  :for={{criterion, value} <- scorecard.scores}
                  class="flex justify-between text-sm"
                >
                  <span class="text-zinc-500 dark:text-zinc-400">{criterion}</span>
                  <span class="font-medium text-zinc-900 dark:text-zinc-100">{value}</span>
                </div>
              </div>

              <div
                :if={scorecard.notes}
                class="text-sm text-zinc-500 dark:text-zinc-400 border-t pt-2"
              >
                {scorecard.notes}
              </div>
            </div>
          </div>
        </div>

        <%!-- Portal Conversations --%>
        <div class="mt-8 bg-white dark:bg-zinc-800 rounded-xl border border-zinc-200 dark:border-zinc-700 shadow-sm p-6">
          <div class="flex justify-between items-center mb-4">
            <h2 class="text-lg font-semibold">{gettext("Portal Conversations")}</h2>
            <div class="flex items-center gap-2">
              <.badge :if={@conversations != []} variant="info" class="text-xs">
                {length(@conversations)}
              </.badge>
              <div class="flex gap-2">
                <.button phx-click="new_portal_message" variant="primary" size="sm">
                  + New Message
                </.button>
                <.button phx-click="request_info" variant="ghost" size="sm">
                  Request Info
                </.button>
                <.button phx-click="reject_candidate" variant="danger" size="sm">
                  Reject
                </.button>
              </div>
            </div>
          </div>

          <%!-- New Message Form --%>
          <div
            :if={@new_message_form_visible}
            class="mb-6 p-4 border rounded-lg bg-blue-50 dark:bg-blue-950"
          >
            <h3 class="text-sm font-medium text-blue-900 mb-3">{gettext("New Portal Message")}</h3>
            <.form
              for={@new_message_form}
              id="new-portal-message-form"
              phx-submit="send_new_message"
              class="space-y-3"
            >
              <.input
                field={@new_message_form[:subject]}
                type="text"
                label={gettext("Subject")}
                placeholder={gettext("Message subject...")}
              />
              <.input
                field={@new_message_form[:body]}
                type="textarea"
                label={gettext("Message")}
                placeholder={gettext("Type your message...")}
                rows={4}
              />
              <div class="flex gap-2">
                <.button type="submit" variant="primary" size="sm">{gettext("Send Message")}</.button>
                <.button type="button" phx-click="cancel_new_message" variant="ghost" size="sm">
                  Cancel
                </.button>
              </div>
            </.form>
          </div>

          <div
            :if={@conversations == [] && !@new_message_form_visible}
            class="text-zinc-400 dark:text-zinc-500 text-sm"
          >
            No conversations yet.
          </div>

          <%!-- Request Info Form --%>
          <div
            :if={@show_request_info_form}
            class="mb-6 p-4 border rounded-lg bg-amber-50 dark:bg-amber-950"
          >
            <h3 class="text-sm font-medium text-amber-900 mb-3">{gettext("Request Information")}</h3>
            <.form
              for={@request_info_form}
              id="request-info-form"
              phx-submit="submit_request_info"
              class="space-y-3"
            >
              <.input
                field={@request_info_form[:template]}
                type="select"
                label={gettext("Template")}
                options={[
                  {gettext("Portfolio/Work Samples"), "portfolio"},
                  {"References", "references"},
                  {"Availability", "availability"},
                  {"Certificates", "certificates"},
                  {"Custom", "custom"}
                ]}
              />
              <.input
                field={@request_info_form[:message]}
                type="textarea"
                label={gettext("Message")}
                placeholder={gettext("Describe what information you need...")}
                rows={3}
              />
              <div class="flex gap-2">
                <.button type="submit" variant="primary" size="sm">
                  Send Request
                </.button>
                <.button type="button" phx-click="cancel_request_info" variant="ghost" size="sm">
                  Cancel
                </.button>
              </div>
            </.form>
          </div>

          <%!-- Reject Form --%>
          <div :if={@show_reject_form} class="mb-6 p-4 border rounded-lg bg-red-50 dark:bg-red-950">
            <h3 class="text-sm font-medium text-red-900 mb-3">{gettext("Reject Candidate")}</h3>
            <.form
              for={@reject_form}
              id="reject-form"
              phx-submit="submit_rejection"
              class="space-y-3"
            >
              <.input
                field={@reject_form[:reason]}
                type="select"
                label={gettext("Reason")}
                options={[
                  {gettext("Not a fit for the role"), "not_fit"},
                  {gettext("Insufficient experience"), "insufficient_experience"},
                  {gettext("Position filled"), "position_filled"},
                  {gettext("Culture fit"), "culture_fit"},
                  {"Other", "other"}
                ]}
              />
              <.input
                field={@reject_form[:feedback]}
                type="textarea"
                label={gettext("Feedback (optional)")}
                placeholder={gettext("Provide constructive feedback...")}
                rows={3}
              />
              <div class="flex gap-2">
                <.button type="submit" variant="danger" size="sm">
                  {gettext("Reject")}
                </.button>
                <.button type="button" phx-click="cancel_reject" variant="ghost" size="sm">
                  Cancel
                </.button>
              </div>
            </.form>
          </div>

          <div
            :if={@completing_interview}
            class="fixed inset-0 bg-black/50 flex items-center justify-center z-50"
            phx-click="cancel_complete_interview"
          >
            <div
              class="bg-white dark:bg-zinc-800 rounded-xl border border-zinc-200 dark:border-zinc-700 shadow-sm-xl max-w-lg w-full mx-4"
              phx-click=""
            >
              <div class="p-6">
                <h2 class="text-lg font-semibold mb-2">{gettext("Mark Interview as Completed")}</h2>
                <p class="text-sm text-zinc-500 dark:text-zinc-400 mb-4">
                  This marks the interview as done. The candidate's stage will not change automatically;
                  you can collect scorecards before advancing.
                </p>
                <div class="flex justify-end gap-2">
                  <.button phx-click="cancel_complete_interview" variant="ghost" size="sm">
                    Cancel
                  </.button>
                  <.button phx-click="confirm_complete_interview" variant="primary" size="sm">
                    Mark as completed
                  </.button>
                </div>
              </div>
            </div>
          </div>

          <div :for={conversation <- @conversations} class="border rounded-lg mb-4 last:mb-0">
            <div class="p-4 border-b bg-zinc-50 dark:bg-zinc-800 rounded-t-lg">
              <div class="flex justify-between items-center">
                <div>
                  <span class="font-medium text-zinc-900 dark:text-zinc-100">
                    {conversation.subject || "Conversation"}
                  </span>
                  <span class="text-sm text-zinc-400 dark:text-zinc-500 ml-2">
                    ({length(conversations_messages(conversation))} message{length(
                      conversations_messages(conversation)
                    ) != 1 && "s"})
                  </span>
                </div>
                <div class="flex items-center gap-2">
                  <.badge
                    variant={if conversation.status == "open", do: "success", else: "default"}
                    class="text-xs"
                  >
                    {conversation.status}
                  </.badge>
                  <span class="text-xs text-zinc-400 dark:text-zinc-500">
                    {if conversation.last_message_at do
                      Calendar.strftime(conversation.last_message_at, "%b %d, %Y at %H:%M")
                    end}
                  </span>
                </div>
              </div>
            </div>

            <div class="p-4 space-y-3">
              <div
                :for={message <- Enum.take(conversations_messages(conversation), -5)}
                class={[
                  "p-3 rounded-lg text-sm",
                  message.sender_type == "candidate" &&
                    "bg-blue-50 dark:bg-blue-950 border-l-4 border-blue-400",
                  message.sender_type == "recruiter" &&
                    "bg-green-50 dark:bg-green-950 border-l-4 border-green-400 ml-8",
                  message.sender_type == "system" &&
                    "bg-gray-50 dark:bg-gray-800/50 text-center text-xs text-zinc-400 dark:text-zinc-500"
                ]}
              >
                <div class="flex justify-between items-center mb-1">
                  <span class="font-medium text-zinc-900 dark:text-zinc-100/80">
                    {String.capitalize(message.sender_type)}
                  </span>
                  <span class="text-xs text-zinc-400 dark:text-zinc-500">
                    {Calendar.strftime(message.inserted_at, "%b %d, %Y at %H:%M")}
                  </span>
                </div>
                <div class="text-zinc-500 dark:text-zinc-400 whitespace-pre-wrap">
                  {message.body}
                </div>
              </div>
            </div>

            <div :if={conversation.status == "open"} class="p-4 border-t">
              <%= if @replying_to_conversation == conversation.id do %>
                <.form
                  for={@conversation_reply_form}
                  id={"conversation-reply-form-#{conversation.id}"}
                  phx-submit="send_conversation_reply"
                  phx-value-conversation_id={conversation.id}
                  class="space-y-3"
                >
                  <.input
                    field={@conversation_reply_form[:body]}
                    type="textarea"
                    label={gettext("Reply")}
                    placeholder={gettext("Type your message...")}
                    rows={3}
                  />
                  <div class="flex gap-2">
                    <.button type="submit" variant="primary" size="sm">{gettext("Send")}</.button>
                    <.button
                      type="button"
                      phx-click="cancel_conversation_reply"
                      variant="ghost"
                      size="sm"
                    >
                      Cancel
                    </.button>
                  </div>
                </.form>
              <% else %>
                <.button
                  phx-click="reply_to_conversation"
                  phx-value-conversation_id={conversation.id}
                  variant="ghost"
                  size="sm"
                >
                  Reply
                </.button>
              <% end %>
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    <.scorecard_form
      show={@show_scorecard_form}
      criteria={@scorecard_criteria}
      form={@scorecard_form}
    />
    <.confirm_dialog
      id="confirm-note"
      show={@confirm_delete != nil}
      title={@confirm_delete && @confirm_delete.title}
      message={@confirm_delete && @confirm_delete.message}
      confirm_label="Delete"
      confirm_variant="danger"
      on_confirm="do_delete_note"
      on_cancel="cancel_delete"
      extra_attrs={(@confirm_delete && %{id: @confirm_delete.id}) || %{}}
    />
    """
  end

  def handle_info({:email, _email}, socket) do
    {:noreply, socket}
  end

  def handle_info({:conversation_updated, _conversation_id}, socket) do
    conversations =
      CandidatePortal.list_conversations_for_candidate(
        socket.assigns.candidate.id,
        socket.assigns.current_tenant.id
      )

    {:noreply, assign(socket, :conversations, conversations)}
  end

  def handle_event("toggle_note_form", %{"application_id" => app_id}, socket) do
    show = if socket.assigns.show_note_form == app_id, do: nil, else: app_id
    {:noreply, assign(socket, show_note_form: show)}
  end

  def handle_event("create_note", %{"note" => note_params, "application_id" => app_id}, socket) do
    attrs =
      Map.merge(note_params, %{
        "application_id" => app_id,
        "author_id" => socket.assigns.current_user.id,
        "tenant_id" => socket.assigns.current_tenant.id
      })

    case Notes.create_note(attrs) do
      {:ok, _note} ->
        applications = reload_applications_with_notes(socket.assigns)

        {:noreply,
         socket
         |> assign(applications: applications, show_note_form: nil)
         |> assign(note_form: to_form(%{}, as: :note))
         |> put_flash(:info, gettext("Note added"))}

      {:error, changeset} ->
        {:noreply,
         socket
         |> assign(note_form: to_form(changeset, as: :note))
         |> put_flash(:error, gettext("Please review the errors below"))}
    end
  end

  def handle_event(
        "confirm_delete",
        %{"id" => id, "title" => title, "message" => message},
        socket
      ) do
    {:noreply, assign(socket, confirm_delete: %{id: id, title: title, message: message})}
  end

  def handle_event("cancel_delete", _params, socket) do
    {:noreply, assign(socket, confirm_delete: nil)}
  end

  def handle_event("do_delete_note", %{"id" => note_id}, socket) do
    note = Notes.get_note!(socket.assigns.current_tenant.id, note_id)

    if note.author_id == socket.assigns.current_user.id do
      {:ok, _} = Notes.delete_note(note)
      applications = reload_applications_with_notes(socket.assigns)

      {:noreply,
       socket
       |> assign(applications: applications, confirm_delete: nil)
       |> put_flash(:info, gettext("Note deleted"))}
    else
      {:noreply,
       socket
       |> assign(confirm_delete: nil)
       |> put_flash(:error, gettext("You can only delete your own notes"))}
    end
  end

  def handle_event("start_edit", _, socket) do
    {:noreply,
     socket
     |> assign(editing?: true)
     |> assign(edit_form: to_form(Candidates.change_candidate(socket.assigns.candidate)))}
  end

  def handle_event("cancel_edit", _, socket) do
    {:noreply,
     socket
     |> assign(editing?: false)
     |> assign(edit_form: to_form(Candidates.change_candidate(socket.assigns.candidate)))}
  end

  def handle_event("save_edit", %{"candidate" => candidate_params}, socket) do
    candidate = socket.assigns.candidate
    metadata = %{actor_id: socket.assigns.current_user.id}

    case Candidates.update_candidate(candidate, candidate_params, metadata) do
      {:ok, updated} ->
        {:noreply,
         socket
         |> assign(candidate: updated)
         |> assign(editing?: false)
         |> assign(edit_form: to_form(Candidates.change_candidate(updated)))
         |> put_flash(:info, gettext("Candidate updated successfully."))}

      {:error, changeset} ->
        {:noreply,
         socket
         |> assign(edit_form: to_form(changeset))
         |> put_flash(:error, gettext("Please review the errors below"))}
    end
  end

  def handle_event("undo_merge", %{"merge_id" => merge_id}, socket) do
    merge_log = Candidates.get_merge_log!(merge_id)
    actor = socket.assigns.current_user

    case Candidates.undo_merge(merge_log, actor) do
      {:ok, %{primary: primary}} ->
        candidate = Candidates.get_candidate(primary.tenant_id, primary.id)
        merge_logs = Candidates.list_merge_logs_for_primary(primary.id)

        {:noreply,
         socket
         |> assign(candidate: candidate)
         |> assign(merge_logs: merge_logs)
         |> assign(edit_form: to_form(Candidates.change_candidate(candidate)))
         |> put_flash(:info, gettext("Merge undone. The absorbed profile has been restored."))}

      {:error, reason} ->
        {:noreply,
         put_flash(
           socket,
           :error,
           gettext("Cannot undo this merge: %{reason}", reason: format_undo_error(reason))
         )}
    end
  end

  def handle_event("new_portal_message", _params, socket) do
    {:noreply,
     socket
     |> assign(:new_message_form_visible, true)
     |> assign(:new_message_form, to_form(%{}, as: :message))}
  end

  def handle_event("cancel_new_message", _params, socket) do
    {:noreply,
     socket
     |> assign(:new_message_form_visible, false)
     |> assign(:new_message_form, to_form(%{}, as: :message))}
  end

  def handle_event("send_new_message", %{"message" => params}, socket) do
    subject = Map.get(params, "subject", "") |> String.trim()
    body = Map.get(params, "body", "") |> String.trim()

    cond do
      subject == "" ->
        {:noreply, put_flash(socket, :error, gettext("Subject is required"))}

      body == "" ->
        {:noreply, put_flash(socket, :error, gettext("Message body is required"))}

      true ->
        application = List.first(socket.assigns.applications)

        {:ok, conversation} =
          CandidatePortal.create_conversation(%{
            candidate_id: socket.assigns.candidate.id,
            tenant_id: socket.assigns.current_tenant.id,
            subject: subject,
            context: "application",
            application_id: if(application, do: application.id)
          })

        CandidatePortal.send_message(%{
          sender_id: socket.assigns.current_user.id,
          sender_type: "recruiter",
          conversation_id: conversation.id,
          body: body,
          message_type: "text"
        })

        CandidatePortal.notify_new_message(
          socket.assigns.candidate,
          socket.assigns.current_tenant,
          "new_message",
          %{
            conversation_id: conversation.id,
            job_title: application && application.job && application.job.title
          }
        )

        conversations =
          CandidatePortal.list_conversations_for_candidate(
            socket.assigns.candidate.id,
            socket.assigns.current_tenant.id
          )

        {:noreply,
         socket
         |> assign(conversations: conversations)
         |> assign(:new_message_form_visible, false)
         |> assign(:new_message_form, to_form(%{}, as: :message))
         |> put_flash(:info, gettext("Message sent"))}
    end
  end

  def handle_event("request_info", _params, socket) do
    {:noreply,
     socket
     |> assign(:show_request_info_form, true)
     |> assign(:request_info_form, to_form(%{}, as: :request_info))}
  end

  def handle_event("cancel_request_info", _params, socket) do
    {:noreply,
     socket
     |> assign(:show_request_info_form, false)
     |> assign(:request_info_form, to_form(%{}, as: :request_info))}
  end

  def handle_event("submit_request_info", %{"request_info" => params}, socket) do
    template = Map.get(params, "template", "custom")
    message = Map.get(params, "message", "") |> String.trim()

    application = List.first(socket.assigns.applications)

    cond do
      message == "" ->
        {:noreply, put_flash(socket, :error, gettext("Message cannot be empty"))}

      is_nil(application) ->
        {:noreply,
         socket
         |> assign(:show_request_info_form, true)
         |> put_flash(
           :error,
           gettext("This candidate has no applications to request information for")
         )}

      true ->
        # Create a conversation with request_info type
        {:ok, conversation} =
          CandidatePortal.create_conversation(%{
            candidate_id: socket.assigns.candidate.id,
            tenant_id: socket.assigns.current_tenant.id,
            subject: gettext("Information Request"),
            context: "info_request",
            application_id: application.id
          })

        CandidatePortal.send_message(%{
          sender_id: socket.assigns.current_user.id,
          sender_type: "recruiter",
          conversation_id: conversation.id,
          body: message,
          message_type: "request_info",
          metadata: %{"template" => template}
        })

        CandidatePortal.notify_new_message(
          socket.assigns.candidate,
          socket.assigns.current_tenant,
          "info_request",
          %{
            conversation_id: conversation.id,
            job_title: application.job && application.job.title
          }
        )

        conversations =
          CandidatePortal.list_conversations_for_candidate(
            socket.assigns.candidate.id,
            socket.assigns.current_tenant.id
          )

        {:noreply,
         socket
         |> assign(conversations: conversations)
         |> assign(:show_request_info_form, false)
         |> assign(:request_info_form, to_form(%{}, as: :request_info))
         |> put_flash(:info, gettext("Information request sent"))}
    end
  end

  def handle_event("reject_candidate", _params, socket) do
    {:noreply,
     socket
     |> assign(:show_reject_form, true)
     |> assign(:reject_form, to_form(%{}, as: :reject))}
  end

  def handle_event("cancel_reject", _params, socket) do
    {:noreply,
     socket
     |> assign(:show_reject_form, false)
     |> assign(:reject_form, to_form(%{}, as: :reject))}
  end

  def handle_event("submit_rejection", %{"reject" => params}, socket) do
    reason = Map.get(params, "reason", "other")
    feedback = Map.get(params, "feedback", "") |> String.trim()

    application = List.first(socket.assigns.applications)

    if application do
      job = application.job

      rejected_stage =
        Pipeline.list_pipeline_stages_for_job(job.id)
        |> Enum.find(&(&1.stage_type == "rejected"))

      if rejected_stage do
        # Create a conversation with rejection
        {:ok, conversation} =
          CandidatePortal.create_conversation(%{
            candidate_id: socket.assigns.candidate.id,
            tenant_id: socket.assigns.current_tenant.id,
            subject: gettext("Application Update"),
            context: "rejection",
            application_id: application.id
          })

        CandidatePortal.send_message(%{
          sender_id: socket.assigns.current_user.id,
          sender_type: "recruiter",
          conversation_id: conversation.id,
          body:
            gettext("We've decided to move forward with other candidates. %{feedback}",
              feedback: feedback
            ),
          message_type: "rejection",
          metadata: %{"rejection_reason" => reason, "feedback" => feedback}
        })

        # Update application status to rejected
        Pipeline.move_application(application, rejected_stage.id, %{
          rejection_reason: reason
        })

        # Send rejection notification email
        try do
          email =
            NotificationEmail.notification_ping(
              socket.assigns.candidate,
              socket.assigns.current_tenant,
              conversation.id,
              "rejection",
              %{"job_title" => job.title}
            )

          Treby.Mailer.deliver(email)
        rescue
          _ -> :ok
        catch
          _ -> :ok
        end

        conversations =
          CandidatePortal.list_conversations_for_candidate(
            socket.assigns.candidate.id,
            socket.assigns.current_tenant.id
          )

        {:noreply,
         socket
         |> assign(conversations: conversations)
         |> assign(:show_reject_form, false)
         |> assign(:reject_form, to_form(%{}, as: :reject))
         |> put_flash(:info, gettext("Candidate rejected"))}
      else
        {:noreply,
         socket
         |> assign(:show_reject_form, true)
         |> put_flash(:error, gettext("No rejected stage found in this pipeline"))}
      end
    else
      {:noreply,
       socket
       |> assign(:show_reject_form, true)
       |> put_flash(:error, gettext("This candidate has no applications to reject"))}
    end
  end

  def handle_event("complete_interview", %{"id" => interview_id}, socket) do
    interview = Treby.Repo.get!(Treby.Interviews.InterviewEvent, interview_id)

    {:noreply, assign(socket, completing_interview: interview)}
  end

  def handle_event("cancel_complete_interview", _params, socket) do
    {:noreply, assign(socket, completing_interview: nil)}
  end

  def handle_event("confirm_complete_interview", _params, socket) do
    interview = socket.assigns.completing_interview

    case Treby.Interviews.complete_interview(interview, socket.assigns.current_user) do
      {:ok, _completed} ->
        interviews = load_interviews_for_candidate(socket.assigns.candidate.id)

        {:noreply,
         socket
         |> assign(interviews: interviews)
         |> assign(completing_interview: nil)
         |> put_flash(:info, gettext("Interview marked as completed"))}

      {:error, _changeset} ->
        {:noreply,
         socket
         |> assign(completing_interview: nil)
         |> put_flash(:error, gettext("Failed to mark interview as completed"))}
    end
  end

  def handle_event("open_scorecard", %{"event_id" => event_id}, socket) do
    template = Scorecards.get_active_template(socket.assigns.current_tenant.id)

    existing_scorecard =
      Scorecards.get_scorecard_for_interview(event_id, socket.assigns.current_user.id)

    criteria = template.criteria || []

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
        candidate_id = socket.assigns.candidate.id
        scorecards = Scorecards.list_scorecards_for_candidate(candidate_id)
        aggregate_scores = Scorecards.compute_aggregate_scores(candidate_id)

        {:noreply,
         socket
         |> assign(show_scorecard_form: false, scorecard_event_id: nil)
         |> assign(scorecards: scorecards, aggregate_scores: aggregate_scores)
         |> put_flash(:info, gettext("Scorecard submitted"))}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, gettext("Failed to submit scorecard"))}
    end
  end

  def handle_event("reply_to_conversation", %{"conversation_id" => conversation_id}, socket) do
    {:noreply,
     socket
     |> assign(:replying_to_conversation, conversation_id)
     |> assign(:conversation_reply_form, to_form(%{}, as: :reply))}
  end

  def handle_event("cancel_conversation_reply", _params, socket) do
    {:noreply,
     socket
     |> assign(:replying_to_conversation, nil)
     |> assign(:conversation_reply_form, to_form(%{}, as: :reply))}
  end

  def handle_event(
        "send_conversation_reply",
        %{"conversation_id" => conversation_id, "reply" => %{"body" => body}},
        socket
      ) do
    body = String.trim(body)

    if body == "" do
      {:noreply, put_flash(socket, :error, gettext("Message cannot be empty"))}
    else
      CandidatePortal.send_message(%{
        sender_id: socket.assigns.current_user.id,
        sender_type: "recruiter",
        conversation_id: conversation_id,
        body: body,
        message_type: "text"
      })

      conversations =
        CandidatePortal.list_conversations_for_candidate(
          socket.assigns.candidate.id,
          socket.assigns.current_tenant.id
        )

      {:noreply,
       socket
       |> assign(conversations: conversations)
       |> assign(:replying_to_conversation, nil)
       |> assign(:conversation_reply_form, to_form(%{}, as: :reply))
       |> put_flash(:info, gettext("Message sent"))}
    end
  end

  defp safe_return_path(nil), do: "/app/candidates"

  defp safe_return_path(return_to) when is_binary(return_to) do
    if String.starts_with?(return_to, "/app/jobs/") or
         String.starts_with?(return_to, "/app/pipeline/") do
      return_to
    else
      "/app/candidates"
    end
  end

  defp safe_return_path(_), do: "/app/candidates"

  defp merged_redirect(primary_id, "/app/candidates"), do: ~p"/app/candidates/#{primary_id}"

  defp merged_redirect(primary_id, return_path) do
    ~p"/app/candidates/#{primary_id}?return_to=#{return_path}"
  end

  defp return_label(path) do
    cond do
      String.starts_with?(path, "/app/pipeline/") -> "Pipeline"
      String.starts_with?(path, "/app/jobs/") -> "Job"
      true -> "Candidates"
    end
  end

  defp format_undo_error(reason) do
    case reason do
      :primary_no_longer_mergeable ->
        "this profile has since been merged into another one"

      :absorbed_not_in_expected_state ->
        "the absorbed profile has already been restored or modified"

      _ ->
        "an unexpected error occurred"
    end
  end

  defp conversations_messages(conversation) do
    conversation.messages || []
  end

  defp reload_applications_with_notes(assigns) do
    Pipeline.list_applications_for_candidate(assigns.current_tenant.id, assigns.candidate.id)
    |> Enum.map(fn app ->
      notes = Notes.list_notes_for_application(app.id)
      Map.put(app, :notes, notes)
    end)
  end

  defp anagrafica_differs?(anagrafica, candidate) do
    String.trim(to_string(anagrafica["name"] || "")) !=
      String.trim(to_string(candidate.name || "")) or
      String.trim(to_string(anagrafica["email"] || "")) !=
        String.trim(to_string(candidate.email || "")) or
      String.trim(to_string(anagrafica["phone"] || "")) !=
        String.trim(to_string(candidate.phone || ""))
  end

  defp humanize_anagrafica_key(key) do
    key |> to_string() |> String.replace("_", " ") |> String.capitalize()
  end

  defp load_interviews_for_candidate(candidate_id) do
    import Ecto.Query

    application_ids =
      Treby.Pipeline.Application
      |> where([a], a.candidate_id == ^candidate_id)
      |> select([a], a.id)
      |> Treby.Repo.all()

    if application_ids != [] do
      Treby.Interviews.InterviewEvent
      |> where([e], e.application_id in ^application_ids)
      |> order_by([e], desc: e.start_at_utc)
      |> preload([:application, examiners: :user])
      |> Treby.Repo.all()
    else
      []
    end
  end
end
