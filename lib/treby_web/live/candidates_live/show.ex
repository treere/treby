defmodule TrebyWeb.CandidatesLive.Show do
  use TrebyWeb, :live_view

  alias Treby.{Accounts, Tenants, Candidates, Pipeline, Notes, Customization}

  def mount(%{"id" => id}, session, socket) do
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

    {:ok,
     socket
     |> assign(current_user: user, current_tenant: tenant)
     |> assign(candidate: candidate)
     |> assign(applications: applications_with_notes)
     |> assign(candidate_fields: candidate_fields)
     |> assign(application_fields: application_fields)
     |> assign(show_note_form: nil)
     |> assign(note_form: to_form(%{}, as: :note))}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_user}>
      <div class="p-8">
        <.link navigate={~p"/app/candidates"} class="text-blue-600 hover:text-blue-900 text-sm">
          &larr; Back to Candidates
        </.link>

        <div class="mt-6 bg-white rounded-lg shadow p-8">
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
          </div>
        </div>

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

  defp reload_applications_with_notes(assigns) do
    Pipeline.list_applications_for_candidate(assigns.current_tenant.id, assigns.candidate.id)
    |> Enum.map(fn app ->
      notes = Notes.list_notes_for_application(app.id)
      Map.put(app, :notes, notes)
    end)
  end
end
