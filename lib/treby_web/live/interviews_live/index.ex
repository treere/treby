defmodule TrebyWeb.InterviewsLive.Index do
  use TrebyWeb, :live_view

  alias Treby.{Accounts, Interviews, Scorecards}

  def mount(_params, session, socket) do
    socket = set_locale_from_session(socket, session)
    user = Accounts.get_user!(session["user_id"])
    tenant = Treby.Tenants.get_tenant!(session["tenant_id"])
    users = Accounts.list_users(tenant.id)

    socket =
      socket
      |> assign(current_user: user, current_tenant: tenant)
      |> assign(page_title: "Interviews")
      |> assign(view: "all")
      |> assign(filter_interviewer_id: nil)
      |> assign(users: users)
      |> assign(show_scorecard_form: false)
      |> assign(scorecard_event_id: nil)
      |> assign(scorecard_form: to_form(%{}))
      |> load_interviews()

    {:ok, socket}
  end

  def handle_params(%{"view" => view}, _url, socket) do
    {:noreply,
     socket
     |> assign(view: view)
     |> load_interviews()}
  end

  def handle_params(_params, _url, socket) do
    {:noreply, load_interviews(socket)}
  end

  def handle_event("set_view", %{"view" => view}, socket) do
    {:noreply,
     socket
     |> assign(view: view)
     |> assign(filter_interviewer_id: nil)
     |> load_interviews()
     |> push_patch(to: ~p"/app/interviews?view=#{view}")}
  end

  def handle_event("filter_interviewer", %{"interviewer_id" => interviewer_id}, socket) do
    filter_id = if interviewer_id == "", do: nil, else: interviewer_id

    {:noreply,
     socket
     |> assign(filter_interviewer_id: filter_id)
     |> load_interviews()}
  end

  def handle_event("cancel_interview", %{"id" => event_id}, socket) do
    event = Interviews.get_event!(event_id)

    case Interviews.cancel_interview(event) do
      {:ok, _event} ->
        {:noreply,
         socket
         |> put_flash(:info, "Interview cancelled")
         |> load_interviews()}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to cancel interview")}
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
    event_id = socket.scorecard_event_id
    criteria = socket.scorecard_criteria

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
        {:noreply,
         socket
         |> assign(show_scorecard_form: false, scorecard_event_id: nil)
         |> put_flash(:info, "Scorecard submitted")
         |> load_interviews()}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to submit scorecard")}
    end
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_user} locale={@locale}>
      <div class="p-8 max-w-6xl mx-auto">
        <div class="flex items-center justify-between mb-8">
          <div>
            <h1 class="text-2xl font-bold text-base-content">Interviews</h1>
            <p class="mt-1 text-sm text-base-content/50">Manage and view all scheduled interviews</p>
          </div>
          <div class="flex items-center gap-3">
            <div class="flex gap-2">
              <button
                phx-click="set_view"
                phx-value-view="all"
                class={[
                  "px-4 py-2 text-sm rounded-md transition-colors",
                  if(@view == "all",
                    do: "bg-blue-600 text-white",
                    else: "bg-base-100 text-base-content/80 border hover:bg-base-200"
                  )
                ]}
              >
                All
              </button>
              <button
                phx-click="set_view"
                phx-value-view="my"
                class={[
                  "px-4 py-2 text-sm rounded-md transition-colors",
                  if(@view == "my",
                    do: "bg-blue-600 text-white",
                    else: "bg-base-100 text-base-content/80 border hover:bg-base-200"
                  )
                ]}
              >
                My Interviews
              </button>
            </div>

            <%= if @view == "all" do %>
              <select
                phx-change="filter_interviewer"
                name="interviewer_id"
                class="select"
              >
                <option value="">All Interviewers</option>
                <%= for user <- @users do %>
                  <option
                    value={user.id}
                    selected={@filter_interviewer_id == user.id}
                  >
                    {user.name}
                  </option>
                <% end %>
              </select>
            <% end %>
          </div>
        </div>

        <div :if={@interviews == []} class="text-center py-12 bg-base-100 rounded-lg border">
          <p class="text-base-content/50">No interviews scheduled yet</p>
        </div>

        <div :if={@interviews != []} class="space-y-3">
          <%= for event <- @interviews do %>
            <div class="bg-base-100 rounded-lg border p-4 hover:shadow-sm transition-shadow">
              <div class="flex items-start justify-between">
                <div class="flex-1">
                  <div class="flex items-center gap-3 mb-2">
                    <h3 class="font-medium text-base-content">
                      {event.application.candidate.name}
                    </h3>
                    <span class="text-sm text-base-content/50">for</span>
                    <span class="font-medium text-base-content/80">
                      {event.application.job.title}
                    </span>
                  </div>

                  <div class="flex items-center gap-4 text-sm text-base-content/50">
                    <span class="flex items-center gap-1">
                      <.icon name="hero-calendar" class="w-4 h-4" />
                      {Elixir.Calendar.strftime(event.start_at_utc, "%B %d, %Y")}
                    </span>
                    <span class="flex items-center gap-1">
                      <.icon name="hero-clock" class="w-4 h-4" />
                      {Elixir.Calendar.strftime(event.start_at_utc, "%H:%M")} - {Elixir.Calendar.strftime(
                        event.end_at_utc,
                        "%H:%M"
                      )}
                    </span>
                    <span class="flex items-center gap-1">
                      <.icon name="hero-user" class="w-4 h-4" />
                      {event.interviewer.name}
                    </span>
                  </div>
                </div>

                <div class="flex items-center gap-2">
                  <%= if event.video_conf_url do %>
                    <a
                      href={event.video_conf_url}
                      target="_blank"
                      class="px-3 py-1 text-sm bg-green-50 dark:bg-green-950 text-green-700 dark:text-green-100 rounded-md hover:bg-green-100"
                    >
                      Join Meet
                    </a>
                  <% end %>
                  <button
                    phx-click="open_scorecard"
                    phx-value-event_id={event.id}
                    class="px-3 py-1 text-sm bg-blue-50 dark:bg-blue-950 text-blue-700 dark:text-blue-100 rounded-md hover:bg-blue-100"
                  >
                    Scorecard
                  </button>
                  <button
                    phx-click="cancel_interview"
                    phx-value-id={event.id}
                    data-confirm="Are you sure you want to cancel this interview?"
                    class="px-3 py-1 text-sm text-red-600 hover:bg-red-50 dark:hover:bg-red-950 rounded-md"
                  >
                    Cancel
                  </button>
                </div>
              </div>
            </div>
          <% end %>
        </div>

        <div
          :if={@show_scorecard_form}
          class="fixed inset-0 bg-black/50 flex items-center justify-center z-50"
        >
          <div class="bg-base-100 rounded-lg shadow-xl max-w-2xl w-full mx-4 max-h-[90vh] overflow-y-auto">
            <div class="p-6">
              <div class="flex justify-between items-center mb-4">
                <h2 class="text-lg font-semibold">Scorecard</h2>
                <button
                  phx-click="close_scorecard"
                  class="text-base-content/40 hover:text-base-content/70"
                >
                  <.icon name="hero-x-mark" class="w-6 h-6" />
                </button>
              </div>

              <.form
                for={@scorecard_form}
                id="scorecard-form"
                phx-submit="submit_scorecard"
                class="space-y-4"
              >
                <div :for={criterion <- @scorecard_criteria} class="space-y-1">
                  <label class="block text-sm font-medium text-base-content/80">
                    {criterion["name"]}
                  </label>
                  <%= cond do %>
                    <% criterion["type"] == "number_1_5" -> %>
                      <div class="flex gap-1">
                        <%= for n <- 1..5 do %>
                          <label class="cursor-pointer">
                            <input
                              type="radio"
                              name={criterion["name"]}
                              value={n}
                              checked={@scorecard_form[criterion["name"]].value == to_string(n)}
                              class="sr-only peer"
                            />
                            <span class="text-2xl peer-checked:text-yellow-500 text-base-content/30 hover:text-yellow-400">
                              ★
                            </span>
                          </label>
                        <% end %>
                      </div>
                    <% criterion["type"] == "yes_no_maybe" -> %>
                      <select
                        name={criterion["name"]}
                        class="select w-full"
                      >
                        <option value="" selected={@scorecard_form[criterion["name"]].value == ""}>
                          Select...
                        </option>
                        <option
                          value="yes"
                          selected={@scorecard_form[criterion["name"]].value == "yes"}
                        >
                          Yes
                        </option>
                        <option value="no" selected={@scorecard_form[criterion["name"]].value == "no"}>
                          No
                        </option>
                        <option
                          value="maybe"
                          selected={@scorecard_form[criterion["name"]].value == "maybe"}
                        >
                          Maybe
                        </option>
                      </select>
                    <% true -> %>
                      <textarea
                        name={criterion["name"]}
                        rows="2"
                        class="textarea w-full"
                      >{@scorecard_form[criterion["name"]].value}</textarea>
                  <% end %>
                </div>

                <div class="space-y-1">
                  <label class="block text-sm font-medium text-base-content/80">Recommendation</label>
                  <select
                    name="recommendation"
                    class="select w-full"
                  >
                    <option value="" selected={@scorecard_form[:recommendation].value == ""}>
                      Select...
                    </option>
                    <option value="hire" selected={@scorecard_form[:recommendation].value == "hire"}>
                      Strong Hire
                    </option>
                    <option
                      value="lean_hire"
                      selected={@scorecard_form[:recommendation].value == "lean_hire"}
                    >
                      Hire
                    </option>
                    <option
                      value="lean_no_hire"
                      selected={@scorecard_form[:recommendation].value == "lean_no_hire"}
                    >
                      Lean No
                    </option>
                    <option
                      value="no_hire"
                      selected={@scorecard_form[:recommendation].value == "no_hire"}
                    >
                      No Hire
                    </option>
                    <option
                      value="strong_no_hire"
                      selected={@scorecard_form[:recommendation].value == "strong_no_hire"}
                    >
                      Strong No Hire
                    </option>
                  </select>
                </div>

                <div class="space-y-1">
                  <label class="block text-sm font-medium text-base-content/80">Notes</label>
                  <textarea
                    name="notes"
                    rows="3"
                    class="textarea w-full"
                  >{@scorecard_form[:notes].value}</textarea>
                </div>

                <div class="flex gap-2 justify-end">
                  <.button type="button" phx-click="close_scorecard" class="bg-gray-500">
                    Cancel
                  </.button>
                  <.button type="submit">Submit Scorecard</.button>
                </div>
              </.form>
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  defp load_interviews(socket) do
    user = socket.assigns.current_user
    tenant_id = socket.assigns.current_tenant.id

    interviews =
      case socket.assigns.view do
        "my" ->
          Interviews.list_upcoming_for_user(user.id)

        _ ->
          base = Interviews.list_upcoming_for_tenant(tenant_id)

          if socket.assigns.filter_interviewer_id do
            Enum.filter(base, &(&1.interviewer_id == socket.assigns.filter_interviewer_id))
          else
            base
          end
      end

    assign(socket, interviews: interviews)
  end
end
