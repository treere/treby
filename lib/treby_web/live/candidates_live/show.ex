defmodule TrebyWeb.CandidatesLive.Show do
  use TrebyWeb, :live_view

  alias Treby.{
    Accounts,
    Tenants,
    Candidates,
    Pipeline,
    Notes,
    Customization,
    Activities,
    Scorecards,
    EmailThreads
  }

  alias TrebyWeb.EmailQueueLive.SchedulePicker

  def mount(%{"id" => id}, session, socket) do
    socket = set_locale_from_session(socket, session)
    user = Accounts.get_user!(session["user_id"])
    tenant = Tenants.get_tenant!(session["tenant_id"])
    candidate = Candidates.get_candidate(tenant.id, id)

    if is_nil(candidate) do
      raise Ecto.NoResultsError, queryable: Candidates.Candidate
    end

    if candidate.merged_into_id do
      primary_id = candidate.merged_into_id

      {:ok,
       socket
       |> assign(current_user: user, current_tenant: tenant)
       |> put_flash(:info, "This candidate was merged into another profile.")
       |> push_navigate(to: ~p"/app/candidates/#{primary_id}")}
    else
      mount_active(socket, candidate, tenant, user)
    end
  end

  defp mount_active(socket, candidate, tenant, user) do
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
        |> preload([:application, :interviewer])
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

    # Load email threads
    email_threads = EmailThreads.list_threads_for_candidate(candidate.id)

    # Get user email for sending replies
    user_email = user.email

    {:ok,
     socket
     |> assign(current_user: user, current_tenant: tenant)
     |> assign(candidate: candidate)
     |> assign(applications: applications_with_notes)
     |> assign(candidate_fields: candidate_fields)
     |> assign(application_fields: application_fields)
     |> assign(interviews: interviews)
     |> assign(scorecards: scorecards)
     |> assign(aggregate_scores: aggregate_scores)
     |> assign(activities: activities)
     |> assign(merge_logs: merge_logs)
     |> assign(email_threads: email_threads)
     |> assign(user_email: user_email)
     |> assign(show_note_form: nil)
     |> assign(note_form: to_form(%{}, as: :note))
     |> assign(editing?: false)
     |> assign(edit_form: to_form(Candidates.change_candidate(candidate)))
     |> assign(replying_to_thread: nil)
     |> assign(confirm_delete: nil)
     |> assign(reply_form: to_form(%{}, as: :reply))
     |> assign(composing_email: false)
     |> assign(compose_form: to_form(%{}, as: :compose))}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_user} locale={@locale}>
      <div class="p-8">
        <.link navigate={~p"/app/candidates"} class="text-blue-600 hover:text-blue-900 text-sm">
          &larr; Back to Candidates
        </.link>

        <div class="mt-6 bg-base-100 rounded-lg shadow p-8">
          <%= if @editing? do %>
            <h2 class="text-lg font-semibold mb-4">Edit Candidate</h2>
            <.form
              for={@edit_form}
              id="edit-candidate-form"
              phx-submit="save_edit"
              class="space-y-4"
            >
              <.input field={@edit_form[:name]} type="text" label="Name" />
              <.input field={@edit_form[:email]} type="email" label="Email" />
              <.input field={@edit_form[:phone]} type="text" label="Phone" />
              <.input field={@edit_form[:linkedin_url]} type="url" label="LinkedIn URL" />

              <div :if={@candidate_fields != []} class="border-t pt-4">
                <h3 class="text-sm font-medium text-base-content/80 mb-3">Custom Fields</h3>
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
                <.button type="submit">Save</.button>
                <.button type="button" phx-click="cancel_edit" class="bg-gray-500">
                  Cancel
                </.button>
              </div>
            </.form>
          <% else %>
            <div class="flex justify-between items-start">
              <div>
                <h1 class="text-2xl font-bold text-base-content">{@candidate.name}</h1>
                <p class="text-base-content/70">{@candidate.email}</p>
                <p :if={@candidate.phone} class="text-base-content/70">{@candidate.phone}</p>
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
              <button
                phx-click="start_edit"
                class="text-sm text-blue-600 hover:text-blue-900 border border-blue-600 rounded px-3 py-1"
              >
                Edit
              </button>
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
                <button
                  phx-click="undo_merge"
                  phx-value-merge_id={log.id}
                  class="text-xs font-medium text-blue-700 hover:text-blue-900 underline"
                >
                  Undo merge
                </button>
              </div>
            </div>

            <div :if={@candidate_fields != []} class="mt-6 border-t pt-4">
              <h3 class="text-sm font-medium text-base-content/80 mb-2">Custom Fields</h3>
              <dl class="grid grid-cols-2 gap-x-4 gap-y-2">
                <div :for={field <- @candidate_fields}>
                  <dt class="text-sm text-base-content/50">{field.name}</dt>
                  <dd class="text-sm text-base-content">
                    {Map.get(@candidate.custom_fields || %{}, field.id, "—")}
                  </dd>
                </div>
              </dl>
            </div>
          <% end %>
        </div>

        <%= if @interviews != [] do %>
          <div class="mt-8">
            <h2 class="text-xl font-semibold text-base-content/90 mb-4">Scheduled Interviews</h2>
            <div class="space-y-3">
              <%= for interview <- @interviews do %>
                <div class={[
                  "bg-base-100 rounded-lg shadow p-4",
                  interview.status == "cancelled" && "opacity-60"
                ]}>
                  <div class="flex items-start justify-between">
                    <div>
                      <p class={[
                        "font-medium text-base-content",
                        interview.status == "cancelled" && "line-through"
                      ]}>
                        {interview.application.job.title}
                      </p>
                      <div class={[
                        "flex items-center gap-4 mt-1 text-sm",
                        interview.status == "cancelled" && "line-through",
                        interview.status == "cancelled" && "text-base-content/40",
                        interview.status != "cancelled" && "text-base-content/50"
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
                          {interview.interviewer.name}
                        </span>
                      </div>
                    </div>
                    <div class="flex items-center gap-2">
                      <span class={[
                        "px-2 py-1 text-xs rounded-full",
                        if(interview.status == "scheduled",
                          do: "bg-green-100 text-green-800",
                          else: "bg-base-200 text-base-content/90"
                        )
                      ]}>
                        {interview.status}
                      </span>
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
          <h2 class="text-xl font-semibold text-base-content/90 mb-4">Applications</h2>
          <div :if={@applications == []} class="text-base-content/50">
            No applications yet.
          </div>
          <div :for={application <- @applications} class="bg-base-100 rounded-lg shadow p-4 mb-4">
            <div class="flex justify-between items-center">
              <div>
                <div class="flex items-center gap-2">
                  <.link
                    navigate={~p"/app/pipeline/#{application.job_id}"}
                    class="font-medium text-blue-600 hover:text-blue-900"
                  >
                    {application.job.title}
                  </.link>
                  <span
                    :if={application.is_duplicate}
                    class="text-xs bg-amber-100 text-amber-800 px-1.5 py-0.5 rounded font-medium"
                  >
                    DUPLICATE APP
                  </span>
                </div>
                <p class="text-sm text-base-content/50">
                  Stage: {application.pipeline_stage.name}
                </p>
                <p :if={application.source} class="text-sm text-base-content/50">
                  Source: {application.source}
                </p>
                <div
                  :if={
                    application.anagrafica && anagrafica_differs?(application.anagrafica, @candidate)
                  }
                  class="mt-2 text-xs bg-yellow-50 dark:bg-yellow-950 border border-yellow-200 dark:border-yellow-900 rounded p-2"
                >
                  <p class="font-medium text-yellow-900 mb-1">As submitted</p>
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
                <span class="text-sm text-base-content/40">
                  {Calendar.strftime(application.inserted_at, "%b %d, %Y")}
                </span>
                <button
                  phx-click="toggle_note_form"
                  phx-value-application_id={application.id}
                  class="text-sm text-blue-600 hover:text-blue-900"
                >
                  Add Note
                </button>
              </div>
            </div>

            <div :if={@application_fields != []} class="mt-3 border-t pt-3">
              <dl class="grid grid-cols-2 gap-x-4 gap-y-1">
                <div :for={field <- @application_fields}>
                  <dt class="text-xs text-base-content/50">{field.name}</dt>
                  <dd class="text-xs text-base-content">
                    {Map.get(application.custom_fields || %{}, field.id, "—")}
                  </dd>
                </div>
              </dl>
            </div>

            <%!-- Notes for this application --%>
            <div :if={application.notes != []} class="mt-4 border-t pt-4">
              <h3 class="text-sm font-medium text-base-content/80 mb-2">Notes</h3>
              <div :for={note <- application.notes} class="mb-3 last:mb-0">
                <div class="flex items-start gap-2">
                  <div class="flex-1">
                    <div class="flex items-center gap-2">
                      <span class="text-sm font-medium text-base-content">{note.author.name}</span>
                      <span
                        :if={note.type == "interview_feedback"}
                        class="text-xs bg-blue-100 text-blue-800 px-1.5 py-0.5 rounded"
                      >
                        Interview Feedback
                      </span>
                      <span :if={note.rating} class="text-xs text-yellow-600">
                        {"★" <> to_string(note.rating) <> "/5"}
                      </span>
                      <span class="text-xs text-base-content/40">
                        {Calendar.strftime(note.inserted_at, "%b %d, %Y at %H:%M")}
                      </span>
                    </div>
                    <p class="text-sm text-base-content/70 mt-1">{note.content}</p>
                  </div>
                  <%= if note.author_id == @current_user.id do %>
                    <button
                      phx-click="confirm_delete"
                      phx-value-id={note.id}
                      phx-value-title="Delete note"
                      phx-value-message="Are you sure you want to delete this note? This action cannot be undone."
                      class="text-xs text-red-500 hover:text-red-700"
                    >
                      Delete
                    </button>
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
                  label="Note"
                  placeholder="Add your note..."
                  rows={3}
                />
                <div class="flex gap-4">
                  <.input
                    field={@note_form[:type]}
                    type="select"
                    label="Type"
                    options={[{"Note", "note"}, {"Interview Feedback", "interview_feedback"}]}
                  />
                  <.input
                    field={@note_form[:rating]}
                    type="select"
                    label="Rating"
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
                  <.button type="submit" class="text-sm">Save Note</.button>
                  <button
                    type="button"
                    phx-click="toggle_note_form"
                    phx-value-application_id=""
                    class="text-sm text-base-content/50 hover:text-base-content/80"
                  >
                    Cancel
                  </button>
                </div>
              </.form>
            </div>
          </div>
        </div>

        <%!-- Activity Timeline --%>
        <div class="mt-8 bg-base-100 rounded-lg shadow p-6">
          <h2 class="text-lg font-semibold mb-4">Activity</h2>
          <.activity_timeline events={@activities} />
        </div>

        <%!-- Scorecards --%>
        <div
          :if={@scorecards != [] || @aggregate_scores.total_scorecards > 0}
          class="mt-8 bg-base-100 rounded-lg shadow p-6"
        >
          <h2 class="text-lg font-semibold mb-4">Scorecards</h2>

          <%!-- Aggregate View --%>
          <div :if={@aggregate_scores.total_scorecards > 0} class="mb-6 p-4 bg-base-200 rounded-lg">
            <h3 class="text-sm font-medium text-base-content/80 mb-3">
              Aggregate ({@aggregate_scores.total_scorecards} scorecard{@aggregate_scores.total_scorecards >
                1 && "s"})
            </h3>

            <div :if={@aggregate_scores.avg_scores != %{}} class="mb-4">
              <h4 class="text-xs font-medium text-base-content/50 uppercase mb-2">Average Scores</h4>
              <div class="grid grid-cols-2 gap-2">
                <div
                  :for={{criterion, avg} <- @aggregate_scores.avg_scores}
                  class="flex justify-between text-sm"
                >
                  <span class="text-base-content/70">{criterion}</span>
                  <span class="font-medium text-base-content">{Float.round(avg, 1)}</span>
                </div>
              </div>
            </div>

            <div :if={@aggregate_scores.recommendation_counts != %{}}>
              <h4 class="text-xs font-medium text-base-content/50 uppercase mb-2">Recommendations</h4>
              <div class="flex gap-3">
                <div :for={{rec, count} <- @aggregate_scores.recommendation_counts} class="text-sm">
                  <span class="text-base-content/70">
                    {String.capitalize(rec |> String.replace("_", " "))}
                  </span>
                  <span class="font-medium text-base-content ml-1">({count})</span>
                </div>
              </div>
            </div>
          </div>

          <%!-- Individual Scorecards --%>
          <div class="space-y-4">
            <div :for={scorecard <- @scorecards} class="border rounded-lg p-4">
              <div class="flex justify-between items-start mb-2">
                <div>
                  <span class="font-medium text-base-content">{scorecard.interviewer.name}</span>
                  <span class="text-sm text-base-content/50 ml-2">
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
                      _ -> "bg-base-200 text-base-content/90"
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
                  <span class="text-base-content/70">{criterion}</span>
                  <span class="font-medium text-base-content">{value}</span>
                </div>
              </div>

              <div :if={scorecard.notes} class="text-sm text-base-content/70 border-t pt-2">
                {scorecard.notes}
              </div>
            </div>
          </div>
        </div>

        <%!-- Email Threads --%>
        <div class="mt-8 bg-base-100 rounded-lg shadow p-6">
          <div class="flex justify-between items-center mb-4">
            <h2 class="text-lg font-semibold">Email History</h2>
            <button
              phx-click="compose_email"
              class="text-sm text-blue-600 hover:text-blue-900 border border-blue-600 rounded px-3 py-1"
            >
              + Compose Email
            </button>
          </div>

          <%!-- Compose form --%>
          <div :if={@composing_email} class="mb-6 p-4 border rounded-lg">
            <.form
              for={@compose_form}
              id="compose-form"
              phx-submit="send_compose"
              class="space-y-3"
            >
              <.input
                field={@compose_form[:subject]}
                type="text"
                label="Subject"
                placeholder="Enter email subject..."
              />
              <.input
                field={@compose_form[:body]}
                type="textarea"
                label="Message"
                placeholder="Type your message..."
                rows={6}
              />
              <div class="p-3 bg-base-200 rounded-lg">
                <.live_component module={SchedulePicker} id="compose-schedule" prefix="compose" />
              </div>
              <div class="flex gap-2">
                <.button type="submit" class="text-sm">Send Email</.button>
                <button
                  type="button"
                  phx-click="cancel_compose"
                  class="text-sm text-base-content/50 hover:text-base-content/80"
                >
                  Cancel
                </button>
              </div>
            </.form>
          </div>

          <div :if={@email_threads == [] && !@composing_email} class="text-base-content/50 text-sm">
            No email threads yet.
          </div>

          <div :for={thread <- @email_threads} class="border rounded-lg mb-4 last:mb-0">
            <div class="p-4 border-b bg-base-200 rounded-t-lg">
              <div class="flex justify-between items-center">
                <div>
                  <span class="font-medium text-base-content">{thread.subject}</span>
                  <span class="text-sm text-base-content/50 ml-2">
                    ({length(thread.messages)} message{length(thread.messages) != 1 && "s"})
                  </span>
                </div>
                <span class="text-xs text-base-content/40">
                  {Calendar.strftime(thread.last_message_at, "%b %d, %Y at %H:%M")}
                </span>
              </div>
            </div>

            <div class="p-4 space-y-3">
              <div
                :for={message <- Enum.reverse(thread.messages)}
                class={[
                  "p-3 rounded-lg text-sm",
                  message.direction == "inbound" &&
                    "bg-blue-50 dark:bg-blue-950 border-l-4 border-blue-400",
                  message.direction == "outbound" &&
                    "bg-green-50 dark:bg-green-950 border-l-4 border-green-400 ml-8",
                  message.status == "scheduled" && "border-dashed opacity-90",
                  message.status == "cancelled" && "opacity-60"
                ]}
              >
                <div class="flex justify-between items-center mb-1">
                  <span class="font-medium text-base-content/80 flex items-center gap-1.5">
                    <.icon
                      :if={message.status == "scheduled"}
                      name="hero-clock"
                      class="w-3.5 h-3.5 text-amber-500"
                    />
                    <.icon
                      :if={message.status == "cancelled"}
                      name="hero-x-mark"
                      class="w-3.5 h-3.5 text-red-400"
                    />
                    {message.direction == "inbound" && "From: #{message.from_address}"}
                    {message.direction == "outbound" && "From: #{message.from_address}"}
                    <span
                      :if={message.status == "scheduled"}
                      class="text-xs text-amber-600 font-medium"
                    >
                      Scheduled
                    </span>
                    <span
                      :if={message.status == "cancelled"}
                      class="text-xs text-red-500 font-medium"
                    >
                      Cancelled
                    </span>
                  </span>
                  <span class="text-xs text-base-content/40">
                    {Calendar.strftime(
                      message.scheduled_at || message.sent_at || message.received_at,
                      "%b %d, %Y at %H:%M"
                    )}
                  </span>
                </div>
                <div
                  :if={message.status != "cancelled"}
                  class="text-base-content/70 whitespace-pre-wrap"
                >
                  {message.body}
                </div>
                <div
                  :if={message.status == "cancelled"}
                  class="text-base-content/40 italic text-xs"
                >
                  Email cancelled — content not available
                </div>
              </div>
            </div>

            <div class="p-4 border-t">
              <button
                phx-click="show_reply_form"
                phx-value-thread_id={thread.id}
                class="text-sm text-blue-600 hover:text-blue-800"
              >
                Reply
              </button>

              <.form
                :if={@replying_to_thread == thread.id}
                for={@reply_form}
                id={"reply-form-#{thread.id}"}
                phx-submit="send_reply"
                phx-value-thread_id={thread.id}
                class="mt-4 space-y-3"
              >
                <.input
                  field={@reply_form[:body]}
                  type="textarea"
                  label="Reply"
                  placeholder="Type your reply..."
                  rows={4}
                />
                <div class="p-3 bg-base-200 rounded-lg">
                  <.live_component
                    module={SchedulePicker}
                    id={"reply-schedule-#{thread.id}"}
                    prefix="reply"
                  />
                </div>
                <div class="flex gap-2">
                  <.button type="submit" class="text-sm">Send Reply</.button>
                  <button
                    type="button"
                    phx-click="cancel_reply"
                    class="text-sm text-base-content/50 hover:text-base-content/80"
                  >
                    Cancel
                  </button>
                </div>
              </.form>
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    <.confirm_modal confirm_delete={@confirm_delete} on_confirm="do_delete_note" />
    """
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
         |> put_flash(:info, "Note added")}

      {:error, changeset} ->
        {:noreply,
         socket
         |> assign(note_form: to_form(changeset, as: :note))
         |> put_flash(:error, "Please review the errors below")}
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
       |> put_flash(:info, "Note deleted")}
    else
      {:noreply,
       socket
       |> assign(confirm_delete: nil)
       |> put_flash(:error, "You can only delete your own notes")}
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
         |> put_flash(:info, "Candidate updated successfully.")}

      {:error, changeset} ->
        {:noreply,
         socket
         |> assign(edit_form: to_form(changeset))
         |> put_flash(:error, "Please review the errors below")}
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
         |> put_flash(:info, "Merge undone. The absorbed profile has been restored.")}

      {:error, reason} ->
        {:noreply,
         put_flash(socket, :error, "Cannot undo this merge: #{format_undo_error(reason)}")}
    end
  end

  def handle_event("show_reply_form", %{"thread_id" => thread_id}, socket) do
    {:noreply,
     socket
     |> assign(replying_to_thread: thread_id)
     |> assign(reply_form: to_form(%{}, as: :reply))}
  end

  def handle_event("cancel_reply", _params, socket) do
    {:noreply,
     socket
     |> assign(replying_to_thread: nil)
     |> assign(reply_form: to_form(%{}, as: :reply))}
  end

  def handle_event("send_reply", %{"thread_id" => thread_id, "reply" => params}, socket) do
    body = Map.get(params, "body", "")
    schedule = build_schedule(params)

    if params["mode"] == "schedule" && is_nil(schedule) do
      {:noreply, put_flash(socket, :error, "Please select a schedule date and time")}
    else
      case EmailThreads.send_reply(
             thread_id,
             socket.assigns.user_email,
             body,
             socket.assigns.current_tenant.id,
             schedule: schedule
           ) do
        {:ok, _message} ->
          # Refresh threads
          email_threads = EmailThreads.list_threads_for_candidate(socket.assigns.candidate.id)

          {:noreply,
           socket
           |> assign(email_threads: email_threads, replying_to_thread: nil)
           |> assign(reply_form: to_form(%{}, as: :reply))
           |> put_flash(:info, if(schedule, do: "Reply scheduled", else: "Reply sent"))}

        {:error, reason} ->
          {:noreply, put_flash(socket, :error, "Failed to send reply: #{inspect(reason)}")}
      end
    end
  end

  def handle_event("compose_email", _params, socket) do
    {:noreply,
     socket
     |> assign(composing_email: true)
     |> assign(compose_form: to_form(%{}, as: :compose))}
  end

  def handle_event("cancel_compose", _params, socket) do
    {:noreply,
     socket
     |> assign(composing_email: false)
     |> assign(compose_form: to_form(%{}, as: :compose))}
  end

  def handle_event("send_compose", %{"compose" => params}, socket) do
    subject = Map.get(params, "subject", "") |> String.trim()
    body = Map.get(params, "body", "") |> String.trim()

    cond do
      subject == "" ->
        {:noreply,
         socket
         |> put_flash(:error, "Subject is required")}

      body == "" ->
        {:noreply,
         socket
         |> put_flash(:error, "Message body is required")}

      true ->
        schedule = build_schedule(params)

        if params["mode"] == "schedule" && is_nil(schedule) do
          {:noreply, put_flash(socket, :error, "Please select a schedule date and time")}
        else
          case EmailThreads.create_outbound_email(%{
                 subject: subject,
                 body: body,
                 from_address: socket.assigns.user_email,
                 candidate_id: socket.assigns.candidate.id,
                 tenant_id: socket.assigns.current_tenant.id,
                 created_by_id: socket.assigns.current_user.id,
                 schedule: schedule
               }) do
            {:ok, _message} ->
              email_threads = EmailThreads.list_threads_for_candidate(socket.assigns.candidate.id)

              {:noreply,
               socket
               |> assign(email_threads: email_threads, composing_email: false)
               |> assign(compose_form: to_form(%{}, as: :compose))
               |> put_flash(:info, if(schedule, do: "Email scheduled", else: "Email sent"))}

            {:error, reason} ->
              {:noreply, put_flash(socket, :error, "Failed to send email: #{inspect(reason)}")}
          end
        end
    end
  end

  defp build_schedule(params) do
    if params["mode"] == "schedule" do
      case DateTime.from_iso8601(params["scheduled_at"] || "") do
        {:ok, dt, _offset} ->
          %{
            scheduled_at: dt,
            jitter_minutes: String.to_integer(params["jitter_minutes"] || "0")
          }

        _ ->
          nil
      end
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
end
