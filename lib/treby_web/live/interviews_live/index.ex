defmodule TrebyWeb.InterviewsLive.Index do
  use TrebyWeb, :live_view

  import TrebyWeb.ScorecardForm, only: [scorecard_form: 1]

  alias Treby.{Accounts, Interviews, Repo, Scorecards}

  def mount(_params, session, socket) do
    socket = set_locale_from_session(socket, session)

    {user, tenant} =
      cond do
        socket.assigns[:current_user] && socket.assigns[:current_tenant] ->
          {socket.assigns.current_user, socket.assigns.current_tenant}

        session["user_id"] && session["tenant_id"] ->
          {Accounts.get_user!(session["user_id"]),
           Treby.Tenants.get_tenant!(session["tenant_id"])}

        session["user_id"] ->
          u = Accounts.get_user!(session["user_id"])

          case Treby.Memberships.list_tenants_for_user(u.id) do
            [%{tenant: t} | _] -> {u, t}
            [] -> {u, nil}
          end

        true ->
          {nil, nil}
      end

    users = Accounts.list_users(tenant.id)

    socket =
      socket
      |> assign(current_user: user, current_tenant: tenant)
      |> assign(page_title: "Interviews")
      |> assign(view: "all")
      |> assign(filter_interviewer_id: nil)
      |> assign(filter_form: to_form(%{}))
      |> assign(users: users)
      |> assign(show_scorecard_form: false)
      |> assign(scorecard_event_id: nil)
      |> assign(scorecard_form: to_form(%{}))
      |> assign(scorecard_criteria: [])
      |> assign(scorecard_template: nil)
      |> assign(completing_interview: nil)
      |> assign(cancelling_interview: nil)
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

  def handle_event("prompt_cancel_interview", %{"id" => event_id}, socket) do
    event = Interviews.get_event!(event_id)
    {:noreply, assign(socket, cancelling_interview: event)}
  end

  def handle_event("cancel_cancel_interview", _params, socket) do
    {:noreply, assign(socket, cancelling_interview: nil)}
  end

  def handle_event("confirm_cancel_interview", %{"id" => event_id}, socket) do
    event = Interviews.get_event!(event_id)

    case Interviews.cancel_interview(event) do
      {:ok, _event} ->
        {:noreply,
         socket
         |> assign(cancelling_interview: nil)
         |> put_flash(:info, gettext("Interview cancelled"))
         |> load_interviews()}

      {:error, _changeset} ->
        {:noreply,
         socket
         |> assign(cancelling_interview: nil)
         |> put_flash(:error, gettext("Failed to cancel interview"))}
    end
  end

  def handle_event("cancel_interview", %{"id" => event_id}, socket) do
    event = Interviews.get_event!(event_id)

    case Interviews.cancel_interview(event) do
      {:ok, _event} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("Interview cancelled"))
         |> load_interviews()}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, gettext("Failed to cancel interview"))}
    end
  end

  def handle_event("complete_interview", %{"id" => event_id}, socket) do
    event = Interviews.get_event!(event_id)

    {:noreply, assign(socket, completing_interview: event)}
  end

  def handle_event("cancel_complete_interview", _params, socket) do
    {:noreply, assign(socket, completing_interview: nil)}
  end

  def handle_event("confirm_complete_interview", _params, socket) do
    event = socket.assigns.completing_interview

    case Interviews.complete_interview(event, socket.assigns.current_user) do
      {:ok, _event} ->
        {:noreply,
         socket
         |> assign(completing_interview: nil)
         |> put_flash(:info, gettext("Interview marked as completed"))
         |> load_interviews()}

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
         |> put_flash(:info, gettext("Scorecard submitted"))
         |> load_interviews()}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, gettext("Failed to submit scorecard"))}
    end
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_user} locale={@locale}>
      <div class="p-8 max-w-6xl mx-auto">
        <.page_header
          title={gettext("Interviews")}
          subtitle={gettext("Manage and view all scheduled interviews")}
        >
          <:actions>
            <div class="flex items-center gap-3">
              <div class="flex gap-2">
                <.button
                  variant={if @view == "all", do: "primary", else: "ghost"}
                  size="sm"
                  phx-click="set_view"
                  phx-value-view="all"
                >
                  {gettext("All")}
                </.button>
                <.button
                  variant={if @view == "my", do: "primary", else: "ghost"}
                  size="sm"
                  phx-click="set_view"
                  phx-value-view="my"
                >
                  {gettext("My Interviews")}
                </.button>
              </div>

              <%= if @view == "all" do %>
                <.form for={@filter_form} id="interviews-filter-form">
                  <select
                    phx-change="filter_interviewer"
                    name="interviewer_id"
                    class="select"
                  >
                    <option value="">{gettext("All Examiners")}</option>
                    <%= for user <- @users do %>
                      <option
                        value={user.id}
                        selected={@filter_interviewer_id == user.id}
                      >
                        {user.name}
                      </option>
                    <% end %>
                  </select>
                </.form>
              <% end %>
            </div>
          </:actions>
        </.page_header>

        <.empty_state
          :if={@interviews == []}
          icon="hero-calendar"
          title={gettext("No interviews scheduled yet")}
          description={
            gettext("No interviews scheduled yet — interviews will appear here once scheduled.")
          }
        />

        <div :if={@interviews != []} class="space-y-3">
          <%= for {event, scorecard_status} <- @interviews do %>
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
                      {event.event_examiners |> Enum.map(& &1.user.name) |> Enum.join(", ")}
                    </span>
                    <span class="flex items-center gap-1">
                      <.icon name="hero-document-text" class="w-4 h-4" />
                      {scorecard_status.completed}/{scorecard_status.total} {gettext("scorecards")}
                    </span>
                  </div>
                </div>

                <div class="flex items-center gap-2">
                  <%= if event.video_conf_url do %>
                    <.button
                      variant="ghost"
                      size="sm"
                      href={event.video_conf_url}
                      target="_blank"
                    >
                      {gettext("Join Meet")}
                    </.button>
                  <% end %>
                  <.button
                    variant="ghost"
                    size="sm"
                    phx-click="open_scorecard"
                    phx-value-event_id={event.id}
                  >
                    {gettext("Scorecard")}
                  </.button>
                  <%= if event.status == "scheduled" do %>
                    <.button
                      variant="ghost"
                      size="sm"
                      phx-click="complete_interview"
                      phx-value-id={event.id}
                    >
                      {gettext("Mark as completed")}
                    </.button>
                  <% end %>
                  <.button
                    variant="danger"
                    size="sm"
                    phx-click="prompt_cancel_interview"
                    phx-value-id={event.id}
                  >
                    {gettext("Cancel")}
                  </.button>
                </div>
              </div>
            </div>
          <% end %>
        </div>

        <.scorecard_form
          show={@show_scorecard_form}
          criteria={@scorecard_criteria}
          form={@scorecard_form}
        />
      </div>

      <.confirm_dialog
        id="complete-interview-dialog"
        show={@completing_interview != nil}
        title={gettext("Mark Interview as Completed")}
        message={
          gettext(
            "This marks the interview as done. The candidate's stage will not change automatically; you can collect scorecards before advancing."
          )
        }
        confirm_label={gettext("Mark as completed")}
        confirm_variant="primary"
        on_confirm="confirm_complete_interview"
        on_cancel="cancel_complete_interview"
      />

      <.confirm_dialog
        id="cancel-interview-dialog"
        show={@cancelling_interview != nil}
        title={gettext("Cancel Interview")}
        message={gettext("Are you sure you want to cancel this interview?")}
        confirm_label={gettext("Cancel")}
        confirm_variant="danger"
        on_confirm="confirm_cancel_interview"
        on_cancel="cancel_cancel_interview"
        extra_attrs={if @cancelling_interview, do: %{id: @cancelling_interview.id}, else: %{}}
      />
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
          base =
            Interviews.list_upcoming_for_tenant(tenant_id)
            |> Repo.preload(event_examiners: [:user], scorecards: [])

          if socket.assigns.filter_interviewer_id do
            Enum.filter(base, fn event ->
              Enum.any?(
                event.event_examiners,
                &(&1.user_id == socket.assigns.filter_interviewer_id)
              )
            end)
          else
            base
          end
      end
      |> Enum.map(fn event ->
        scorecard_status = Interviews.scorecard_completion_status(event)
        {event, scorecard_status}
      end)

    assign(socket, interviews: interviews)
  end
end
