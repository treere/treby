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

  def mount(%{"id" => id}, session, socket) do
    socket = set_locale_from_session(socket, session)
    user = Accounts.get_user!(session["user_id"])
    tenant = Tenants.get_tenant!(session["tenant_id"])
    candidate = Candidates.get_candidate!(tenant.id, id)
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
     |> assign(email_threads: email_threads)
     |> assign(user_email: user_email)
     |> assign(show_note_form: nil)
     |> assign(note_form: to_form(%{}, as: :note))
     |> assign(editing?: false)
     |> assign(edit_form: to_form(Candidates.change_candidate(candidate)))
     |> assign(replying_to_thread: nil)
     |> assign(reply_form: to_form(%{}, as: :reply))}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_user} locale={@locale}>
      <div class="p-8">
        <.link navigate={~p"/app/candidates"} class="text-blue-600 hover:text-blue-900 text-sm">
          &larr; Back to Candidates
        </.link>

        <div class="mt-6 bg-white rounded-lg shadow p-8">
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
                <h3 class="text-sm font-medium text-gray-700 mb-3">Custom Fields</h3>
                <div :for={field <- @candidate_fields} class="mb-3">
                  <%= cond do %>
                    <% field.field_type == "select" -> %>
                      <label class="block text-sm font-medium text-gray-700 mb-1">{field.name}</label>
                      <select
                        name={"custom_fields[#{field.id}]"}
                        class="block w-full rounded-lg border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 text-sm"
                      >
                        <option value="">—</option>
                        <option
                          :for={opt <- field.options}
                          value={opt}
                          selected={opt == Map.get(@candidate.custom_fields || %{}, field.id)}
                        >
                          {opt}
                        </option>
                      </select>
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
                <h1 class="text-2xl font-bold text-gray-900">{@candidate.name}</h1>
                <p class="text-gray-600">{@candidate.email}</p>
                <p :if={@candidate.phone} class="text-gray-600">{@candidate.phone}</p>
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

            <div :if={@candidate_fields != []} class="mt-6 border-t pt-4">
              <h3 class="text-sm font-medium text-gray-700 mb-2">Custom Fields</h3>
              <dl class="grid grid-cols-2 gap-x-4 gap-y-2">
                <div :for={field <- @candidate_fields}>
                  <dt class="text-sm text-gray-500">{field.name}</dt>
                  <dd class="text-sm text-gray-900">
                    {Map.get(@candidate.custom_fields || %{}, field.id, "—")}
                  </dd>
                </div>
              </dl>
            </div>
          <% end %>
        </div>

        <%= if @interviews != [] do %>
          <div class="mt-8">
            <h2 class="text-xl font-semibold text-gray-800 mb-4">Scheduled Interviews</h2>
            <div class="space-y-3">
              <%= for interview <- @interviews do %>
                <div class={[
                  "bg-white rounded-lg shadow p-4",
                  interview.status == "cancelled" && "opacity-60"
                ]}>
                  <div class="flex items-start justify-between">
                    <div>
                      <p class={[
                        "font-medium text-gray-900",
                        interview.status == "cancelled" && "line-through"
                      ]}>
                        {interview.application.job.title}
                      </p>
                      <div class={[
                        "flex items-center gap-4 mt-1 text-sm",
                        interview.status == "cancelled" && "line-through",
                        interview.status == "cancelled" && "text-gray-400",
                        interview.status != "cancelled" && "text-gray-500"
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
                          else: "bg-gray-100 text-gray-800"
                        )
                      ]}>
                        {interview.status}
                      </span>
                      <%= if interview.video_conf_url do %>
                        <a
                          href={interview.video_conf_url}
                          target="_blank"
                          class="px-3 py-1 text-sm bg-green-50 text-green-700 rounded-md hover:bg-green-100"
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
          <h2 class="text-xl font-semibold text-gray-800 mb-4">Applications</h2>
          <div :if={@applications == []} class="text-gray-500">
            No applications yet.
          </div>
          <div :for={application <- @applications} class="bg-white rounded-lg shadow p-4 mb-4">
            <div class="flex justify-between items-center">
              <div>
                <.link
                  navigate={~p"/app/pipeline/#{application.job_id}"}
                  class="font-medium text-blue-600 hover:text-blue-900"
                >
                  {application.job.title}
                </.link>
                <p class="text-sm text-gray-500">
                  Stage: {application.pipeline_stage.name}
                </p>
                <p :if={application.source} class="text-sm text-gray-500">
                  Source: {application.source}
                </p>
              </div>
              <div class="flex items-center gap-3">
                <a
                  :if={application.resume_url}
                  href={~p"/app/applications/#{application.id}/resume"}
                  class="text-sm text-blue-600 hover:text-blue-900"
                >
                  View Resume
                </a>
                <span class="text-sm text-gray-400">
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
                  <dt class="text-xs text-gray-500">{field.name}</dt>
                  <dd class="text-xs text-gray-900">
                    {Map.get(application.custom_fields || %{}, field.id, "—")}
                  </dd>
                </div>
              </dl>
            </div>

            <%!-- Notes for this application --%>
            <div :if={application.notes != []} class="mt-4 border-t pt-4">
              <h3 class="text-sm font-medium text-gray-700 mb-2">Notes</h3>
              <div :for={note <- application.notes} class="mb-3 last:mb-0">
                <div class="flex items-start gap-2">
                  <div class="flex-1">
                    <div class="flex items-center gap-2">
                      <span class="text-sm font-medium text-gray-900">{note.author.name}</span>
                      <span
                        :if={note.type == "interview_feedback"}
                        class="text-xs bg-blue-100 text-blue-800 px-1.5 py-0.5 rounded"
                      >
                        Interview Feedback
                      </span>
                      <span :if={note.rating} class="text-xs text-yellow-600">
                        {"★" <> to_string(note.rating) <> "/5"}
                      </span>
                      <span class="text-xs text-gray-400">
                        {Calendar.strftime(note.inserted_at, "%b %d, %Y at %H:%M")}
                      </span>
                    </div>
                    <p class="text-sm text-gray-600 mt-1">{note.content}</p>
                  </div>
                  <%= if note.author_id == @current_user.id do %>
                    <button
                      phx-click="delete_note"
                      phx-value-note_id={note.id}
                      phx-value-application_id={application.id}
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
                    class="text-sm text-gray-500 hover:text-gray-700"
                  >
                    Cancel
                  </button>
                </div>
              </.form>
            </div>
          </div>
        </div>

        <%!-- Activity Timeline --%>
        <div class="mt-8 bg-white rounded-lg shadow p-6">
          <h2 class="text-lg font-semibold mb-4">Activity</h2>
          <.activity_timeline events={@activities} />
        </div>

        <%!-- Scorecards --%>
        <div
          :if={@scorecards != [] || @aggregate_scores.total_scorecards > 0}
          class="mt-8 bg-white rounded-lg shadow p-6"
        >
          <h2 class="text-lg font-semibold mb-4">Scorecards</h2>

          <%!-- Aggregate View --%>
          <div :if={@aggregate_scores.total_scorecards > 0} class="mb-6 p-4 bg-gray-50 rounded-lg">
            <h3 class="text-sm font-medium text-gray-700 mb-3">
              Aggregate ({@aggregate_scores.total_scorecards} scorecard{@aggregate_scores.total_scorecards >
                1 && "s"})
            </h3>

            <div :if={@aggregate_scores.avg_scores != %{}} class="mb-4">
              <h4 class="text-xs font-medium text-gray-500 uppercase mb-2">Average Scores</h4>
              <div class="grid grid-cols-2 gap-2">
                <div
                  :for={{criterion, avg} <- @aggregate_scores.avg_scores}
                  class="flex justify-between text-sm"
                >
                  <span class="text-gray-600">{criterion}</span>
                  <span class="font-medium text-gray-900">{Float.round(avg, 1)}</span>
                </div>
              </div>
            </div>

            <div :if={@aggregate_scores.recommendation_counts != %{}}>
              <h4 class="text-xs font-medium text-gray-500 uppercase mb-2">Recommendations</h4>
              <div class="flex gap-3">
                <div :for={{rec, count} <- @aggregate_scores.recommendation_counts} class="text-sm">
                  <span class="text-gray-600">
                    {String.capitalize(rec |> String.replace("_", " "))}
                  </span>
                  <span class="font-medium text-gray-900 ml-1">({count})</span>
                </div>
              </div>
            </div>
          </div>

          <%!-- Individual Scorecards --%>
          <div class="space-y-4">
            <div :for={scorecard <- @scorecards} class="border rounded-lg p-4">
              <div class="flex justify-between items-start mb-2">
                <div>
                  <span class="font-medium text-gray-900">{scorecard.interviewer.name}</span>
                  <span class="text-sm text-gray-500 ml-2">
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
                      _ -> "bg-gray-100 text-gray-800"
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
                  <span class="text-gray-600">{criterion}</span>
                  <span class="font-medium text-gray-900">{value}</span>
                </div>
              </div>

              <div :if={scorecard.notes} class="text-sm text-gray-600 border-t pt-2">
                {scorecard.notes}
              </div>
            </div>
          </div>
        </div>

        <%!-- Email Threads --%>
        <div class="mt-8 bg-white rounded-lg shadow p-6">
          <h2 class="text-lg font-semibold mb-4">Email History</h2>

          <div :if={@email_threads == []} class="text-gray-500 text-sm">
            No email threads yet.
          </div>

          <div :for={thread <- @email_threads} class="border rounded-lg mb-4 last:mb-0">
            <div class="p-4 border-b bg-gray-50 rounded-t-lg">
              <div class="flex justify-between items-center">
                <div>
                  <span class="font-medium text-gray-900">{thread.subject}</span>
                  <span class="text-sm text-gray-500 ml-2">
                    ({length(thread.messages)} message{length(thread.messages) != 1 && "s"})
                  </span>
                </div>
                <span class="text-xs text-gray-400">
                  {Calendar.strftime(thread.last_message_at, "%b %d, %Y at %H:%M")}
                </span>
              </div>
            </div>

            <div class="p-4 space-y-3">
              <div
                :for={message <- Enum.reverse(thread.messages)}
                class={[
                  "p-3 rounded-lg text-sm",
                  message.direction == "inbound" && "bg-blue-50 border-l-4 border-blue-400",
                  message.direction == "outbound" && "bg-green-50 border-l-4 border-green-400 ml-8"
                ]}
              >
                <div class="flex justify-between items-center mb-1">
                  <span class="font-medium text-gray-700">
                    {message.direction == "inbound" && "From: #{message.from_address}"}
                    {message.direction == "outbound" && "From: #{message.from_address}"}
                  </span>
                  <span class="text-xs text-gray-400">
                    {Calendar.strftime(
                      message.sent_at || message.received_at,
                      "%b %d, %Y at %H:%M"
                    )}
                  </span>
                </div>
                <div class="text-gray-600 whitespace-pre-wrap">
                  {message.body}
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
                <div class="flex gap-2">
                  <.button type="submit" class="text-sm">Send Reply</.button>
                  <button
                    type="button"
                    phx-click="cancel_reply"
                    class="text-sm text-gray-500 hover:text-gray-700"
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
        {:noreply, assign(socket, note_form: to_form(changeset, as: :note))}
    end
  end

  def handle_event("delete_note", %{"note_id" => note_id, "application_id" => _app_id}, socket) do
    note = Notes.get_note!(socket.assigns.current_tenant.id, note_id)

    if note.author_id == socket.assigns.current_user.id do
      {:ok, _} = Notes.delete_note(note)
      applications = reload_applications_with_notes(socket.assigns)

      {:noreply,
       socket
       |> assign(applications: applications)
       |> put_flash(:info, "Note deleted")}
    else
      {:noreply, put_flash(socket, :error, "You can only delete your own notes")}
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
        {:noreply, assign(socket, edit_form: to_form(changeset))}
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

    case EmailThreads.send_reply(
           thread_id,
           socket.assigns.user_email,
           body,
           socket.assigns.current_tenant.id
         ) do
      {:ok, _message} ->
        # Refresh threads
        email_threads = EmailThreads.list_threads_for_candidate(socket.assigns.candidate.id)

        {:noreply,
         socket
         |> assign(email_threads: email_threads, replying_to_thread: nil)
         |> assign(reply_form: to_form(%{}, as: :reply))
         |> put_flash(:info, "Reply sent")}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Failed to send reply: #{inspect(reason)}")}
    end
  end

  defp reload_applications_with_notes(assigns) do
    Pipeline.list_applications_for_candidate(assigns.current_tenant.id, assigns.candidate.id)
    |> Enum.map(fn app ->
      notes = Notes.list_notes_for_application(app.id)
      Map.put(app, :notes, notes)
    end)
  end
end
