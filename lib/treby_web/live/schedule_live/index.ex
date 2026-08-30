defmodule TrebyWeb.ScheduleLive.Index do
  use TrebyWeb, :live_view

  alias Treby.{Accounts, Tenants, Calendar, Availability, Interviews, Pipeline}
  alias Treby.Calendar.Providers.Jitsi

  def mount(%{"application_id" => application_id}, session, socket) do
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

    case Pipeline.get_application(application_id) do
      nil ->
        {:ok, redirect(socket, to: ~p"/404")}

      application ->
        interview_stage =
          Pipeline.list_pipeline_stages_for_job(application.job.id)
          |> Enum.find(&(&1.stage_type == "interview"))

        users =
          if interview_stage do
            Pipeline.list_eligible_examiners(interview_stage)
            |> Enum.map(& &1.user)
            |> Enum.reject(&is_nil/1)
          else
            []
          end

        connected_ids =
          tenant.id
          |> Calendar.list_connected_users()
          |> Enum.map(& &1.user_id)
          |> MapSet.new()

        fallback_users = Accounts.list_users(tenant.id)

        {:ok,
         socket
         |> assign(current_user: user, current_tenant: tenant)
         |> assign(application: application)
         |> assign(users: users)
         |> assign(connected_ids: connected_ids)
         |> assign(fallback_users: fallback_users)
         |> assign(selected_user: nil)
         |> assign(slots: [])
         |> assign(selected_slot: nil)
         |> assign(selected_date: Date.utc_today())
         |> assign(ad_hoc_date: Date.to_iso8601(Date.utc_today()))
         |> assign(ad_hoc_time: "09:00")
         |> assign(ad_hoc_user_id: nil)}
    end
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_user} locale={@locale}>
      <div class="p-8">
        <div class="mb-8">
          <.link
            navigate={~p"/app/candidates/#{@application.candidate_id}"}
            class="text-blue-600 hover:text-blue-900 text-sm"
          >
            &larr; Back to Candidate
          </.link>
          <h1 class="text-2xl font-bold mt-2">Schedule Interview</h1>
          <p class="mt-1 text-base-content/70">
            Scheduling for <strong>{@application.candidate.name}</strong> — {@application.job.title}
          </p>
        </div>

        <div class="grid grid-cols-1 lg:grid-cols-3 gap-8">
          <div class="lg:col-span-2">
            <div class="bg-base-100 rounded-lg shadow p-6">
              <h2 class="text-lg font-semibold mb-4">Select Interviewer</h2>
              <div :if={@users == []} class="space-y-4">
                <div class="text-center py-4">
                  <p class="text-base-content/50 text-sm">
                    No team members have set their availability yet.
                  </p>
                  <p class="text-xs text-base-content/40 mt-1">
                    Schedule ad-hoc without weekly rules — or
                    <.link
                      navigate={~p"/app/settings/availability"}
                      class="text-blue-600 hover:text-blue-800"
                    >
                      Set weekly availability → Settings → Availability
                    </.link>
                  </p>
                </div>
                <div class="border rounded-lg p-4 bg-base-200/50 space-y-3">
                  <div class="grid grid-cols-2 gap-3">
                    <div>
                      <label class="block text-xs font-medium text-base-content/70 mb-1">Date</label>
                      <input
                        type="date"
                        value={@ad_hoc_date}
                        phx-change="ad_hoc_date"
                        class="input w-full"
                      />
                    </div>
                    <div>
                      <label class="block text-xs font-medium text-base-content/70 mb-1">
                        Time (UTC)
                      </label>
                      <input
                        type="time"
                        value={@ad_hoc_time}
                        phx-change="ad_hoc_time"
                        class="input w-full"
                      />
                    </div>
                  </div>
                  <div>
                    <label class="block text-xs font-medium text-base-content/70 mb-1">
                      Interviewer
                    </label>
                    <select phx-change="ad_hoc_user" class="select w-full">
                      <option value="">Select interviewer</option>
                      <option
                        :for={u <- @fallback_users}
                        value={u.id}
                        selected={@ad_hoc_user_id == u.id}
                      >
                        {u.name} — {u.email}
                      </option>
                    </select>
                  </div>
                  <button
                    phx-click="book_ad_hoc"
                    disabled={is_nil(@ad_hoc_user_id) or @ad_hoc_date == "" or @ad_hoc_time == ""}
                    class="w-full px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed"
                  >
                    Book Interview
                  </button>
                </div>
              </div>

              <div :if={@users != []} class="space-y-2">
                <%= for user <- @users do %>
                  <button
                    phx-click="select_user"
                    phx-value-user_id={user.id}
                    class={[
                      "w-full text-left px-4 py-3 rounded-lg border transition-colors",
                      if(@selected_user && @selected_user.id == user.id,
                        do: "border-blue-500 bg-blue-50 dark:bg-blue-950",
                        else: "border-base-300 hover:border-base-300"
                      )
                    ]}
                  >
                    <span class="font-medium">{user.name}</span>
                    <span class="text-sm text-base-content/50 ml-2">{user.email}</span>
                    <%= if MapSet.member?(@connected_ids, user.id) do %>
                      <span class="ml-2 inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800">
                        Google connected
                      </span>
                    <% end %>
                  </button>
                <% end %>
              </div>

              <%= if @selected_user do %>
                <div class="mt-6 pt-6 border-t">
                  <h3 class="font-medium mb-3">Available Slots</h3>

                  <div class="flex items-center gap-4 mb-4">
                    <button
                      phx-click="prev_week"
                      class="px-3 py-1 border rounded hover:bg-base-200"
                    >
                      &larr; Prev
                    </button>
                    <span class="text-sm text-base-content/70">
                      {Elixir.Calendar.strftime(@selected_date, "%B %d")} - {Date.add(
                        @selected_date,
                        6
                      )
                      |> Elixir.Calendar.strftime("%B %d, %Y")}
                    </span>
                    <button
                      phx-click="next_week"
                      class="px-3 py-1 border rounded hover:bg-base-200"
                    >
                      Next &rarr;
                    </button>
                  </div>

                  <div :if={@slots == []} class="text-center py-8">
                    <p class="text-base-content/50 text-sm">No available slots for this week</p>
                  </div>

                  <div :if={@slots != []} class="grid grid-cols-7 gap-2">
                    <%= for slot <- @slots do %>
                      <button
                        phx-click="select_slot"
                        phx-value-start={slot.start |> DateTime.to_iso8601()}
                        class={[
                          "px-3 py-2 text-xs rounded border text-center transition-colors",
                          if(@selected_slot && @selected_slot.start == slot.start,
                            do: "border-blue-500 bg-blue-500 text-white",
                            else: "border-base-300 hover:border-blue-300"
                          )
                        ]}
                      >
                        {slot.start |> Elixir.Calendar.strftime("%a %H:%M")}
                      </button>
                    <% end %>
                  </div>
                </div>
              <% end %>
            </div>
          </div>

          <div class="lg:col-span-1">
            <div class="bg-base-100 rounded-lg shadow p-6">
              <h2 class="text-lg font-semibold mb-4">Details</h2>
              <dl class="space-y-3 text-sm">
                <div>
                  <dt class="text-base-content/50">Candidate</dt>
                  <dd class="font-medium">{@application.candidate.name}</dd>
                </div>
                <div>
                  <dt class="text-base-content/50">Job</dt>
                  <dd class="font-medium">{@application.job.title}</dd>
                </div>
                <div>
                  <dt class="text-base-content/50">Interview Type</dt>
                  <dd class="font-medium">Video</dd>
                </div>
                <div :if={@selected_slot}>
                  <dt class="text-base-content/50">Selected Time</dt>
                  <dd class="font-medium">
                    {Elixir.Calendar.strftime(@selected_slot.start, "%B %d, %Y at %H:%M UTC")}
                  </dd>
                </div>
              </dl>

              <%= if @selected_slot && @selected_user do %>
                <button
                  phx-click="book_interview"
                  class="mt-6 w-full px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700"
                >
                  Book Interview
                </button>
              <% end %>

              <div class="mt-6 pt-6 border-t">
                <h3 class="text-sm font-medium text-base-content/80 mb-2">Self-Scheduling</h3>
                <p class="text-xs text-base-content/50">
                  The candidate can choose their own time slot from their application portal.
                  Send them a message in the portal to let them know they can book.
                </p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  def handle_event("ad_hoc_date", %{"value" => date}, socket) do
    {:noreply, assign(socket, ad_hoc_date: date)}
  end

  def handle_event("ad_hoc_time", %{"value" => time}, socket) do
    {:noreply, assign(socket, ad_hoc_time: time)}
  end

  def handle_event("ad_hoc_user", %{"value" => user_id}, socket) do
    {:noreply, assign(socket, ad_hoc_user_id: user_id)}
  end

  def handle_event("book_ad_hoc", _params, socket) do
    %{ad_hoc_date: date_str, ad_hoc_time: time_str, ad_hoc_user_id: user_id, application: app} =
      socket.assigns

    cond do
      is_nil(user_id) or user_id == "" ->
        {:noreply, put_flash(socket, :error, "Select an interviewer")}

      date_str == "" or time_str == "" ->
        {:noreply, put_flash(socket, :error, "Select date and time")}

      true ->
        with {:ok, date} <- Date.from_iso8601(date_str),
             {:ok, time} <- Time.from_iso8601(time_str),
             {:ok, start_at} <- DateTime.new(date, time, "Etc/UTC") do
          end_at = DateTime.add(start_at, 30, :minute)
          interviewer = Enum.find(socket.assigns.fallback_users, &(&1.id == user_id))

          base_attrs = %{
            start_at_utc: start_at,
            end_at_utc: end_at,
            duration_minutes: 30,
            examiner_ids: [user_id],
            scheduled_by_id: socket.assigns.current_user.id,
            application_id: app.id,
            tenant_id: socket.assigns.current_tenant.id
          }

          examiner_emails = if interviewer, do: [interviewer.email], else: []

          event_params = %{
            summary: "Interview with #{app.candidate.name} - #{app.job.title}",
            description: "Scheduled via Treby",
            start_at: start_at,
            end_at: end_at,
            timezone: "UTC"
          }

          case Calendar.resolve_meeting([user_id]) do
            {:calendar_event, owner_id, :google_meet} ->
              attendee_emails = examiner_emails ++ [app.candidate.email]

              case Calendar.create_event_with_meet(
                     owner_id,
                     "google",
                     event_params,
                     attendee_emails
                   ) do
                {:ok, event_result} ->
                  attrs =
                    base_attrs
                    |> Map.put(:video_conf_url, event_result.video_link)
                    |> Map.put(:provider_event_id, event_result.provider_event_id)
                    |> Map.put(:calendar_provider, "google")
                    |> Map.put(:calendar_owner_id, owner_id)

                  book_interview(socket, attrs, app.candidate_id)

                {:error, _} ->
                  {:noreply,
                   socket
                   |> put_flash(:error, "Failed to create calendar event. Please try again.")}
              end

            {:meeting_url, :jitsi} ->
              {:ok, meet_url} =
                Jitsi.create_meeting_link(%{tenant_slug: socket.assigns.current_tenant.slug})

              attrs = base_attrs |> Map.put(:video_conf_url, meet_url)
              book_interview(socket, attrs, app.candidate_id)
          end
        else
          _ -> {:noreply, put_flash(socket, :error, "Invalid date or time")}
        end
    end
  end

  def handle_event("select_user", %{"user_id" => user_id}, socket) do
    user = Enum.find(socket.assigns.users, &(&1.id == user_id))

    date_range = %{
      from: socket.assigns.selected_date,
      to: Date.add(socket.assigns.selected_date, 6)
    }

    case Availability.compute_slots(user_id, date_range) do
      slots when is_list(slots) ->
        {:noreply,
         socket
         |> assign(selected_user: user, slots: slots, selected_slot: nil)}

      {:error, reason} ->
        {:noreply,
         socket
         |> assign(selected_user: user, slots: [], selected_slot: nil)
         |> put_flash(:error, "Could not load availability: #{inspect(reason)}")}
    end
  end

  def handle_event("select_slot", %{"start" => start_iso}, socket) do
    {:ok, start_dt, _} = DateTime.from_iso8601(start_iso)
    slot = Enum.find(socket.assigns.slots, &(DateTime.compare(&1.start, start_dt) == :eq))

    {:noreply, assign(socket, selected_slot: slot)}
  end

  def handle_event("prev_week", _, socket) do
    new_date = Date.add(socket.assigns.selected_date, -7)
    slots = recompute_slots(socket, new_date)

    {:noreply, assign(socket, selected_date: new_date, slots: slots, selected_slot: nil)}
  end

  def handle_event("next_week", _, socket) do
    new_date = Date.add(socket.assigns.selected_date, 7)
    slots = recompute_slots(socket, new_date)

    {:noreply, assign(socket, selected_date: new_date, slots: slots, selected_slot: nil)}
  end

  def handle_event("book_interview", _, socket) do
    %{selected_slot: slot, selected_user: interviewer, application: app} = socket.assigns

    unless slot && interviewer do
      {:noreply, put_flash(socket, :error, "Please select an interviewer and time slot")}
    else
      examiner_ids = [interviewer.id]

      event_params = %{
        summary: "Interview with #{app.candidate.name} - #{app.job.title}",
        description: "Scheduled via Treby",
        start_at: slot.start,
        end_at: slot.end,
        timezone: "UTC"
      }

      base_attrs = %{
        start_at_utc: slot.start,
        end_at_utc: slot.end,
        duration_minutes: 30,
        examiner_ids: examiner_ids,
        scheduled_by_id: socket.assigns.current_user.id,
        application_id: app.id,
        tenant_id: socket.assigns.current_tenant.id
      }

      case Calendar.resolve_meeting(examiner_ids) do
        {:calendar_event, owner_id, :google_meet} ->
          attendee_emails = [interviewer.email, app.candidate.email]

          case Calendar.create_event_with_meet(
                 owner_id,
                 "google",
                 event_params,
                 attendee_emails
               ) do
            {:ok, event_result} ->
              attrs =
                base_attrs
                |> Map.put(:video_conf_url, event_result.video_link)
                |> Map.put(:provider_event_id, event_result.provider_event_id)
                |> Map.put(:calendar_provider, "google")
                |> Map.put(:calendar_owner_id, owner_id)

              book_interview(socket, attrs, app.candidate_id)

            {:error, _reason} ->
              {:noreply,
               socket
               |> assign(selected_slot: nil)
               |> put_flash(:error, "Failed to create calendar event. Please try again.")}
          end

        {:meeting_url, :jitsi} ->
          {:ok, meet_url} =
            Jitsi.create_meeting_link(%{tenant_slug: socket.assigns.current_tenant.slug})

          attrs = base_attrs |> Map.put(:video_conf_url, meet_url)
          book_interview(socket, attrs, app.candidate_id)
      end
    end
  end

  defp book_interview(socket, attrs, candidate_id) do
    case Interviews.schedule_interview(attrs) do
      {:ok, _event} ->
        {:noreply,
         socket
         |> put_flash(:info, "Interview scheduled successfully!")
         |> push_navigate(to: ~p"/app/candidates/#{candidate_id}")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to schedule interview")}
    end
  end

  defp recompute_slots(socket, new_date) do
    if socket.assigns.selected_user do
      date_range = %{from: new_date, to: Date.add(new_date, 6)}

      case Availability.compute_slots(socket.assigns.selected_user.id, date_range) do
        slots when is_list(slots) -> slots
        {:error, _} -> socket.assigns.slots
      end
    else
      []
    end
  end
end
