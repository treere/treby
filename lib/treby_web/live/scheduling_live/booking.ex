defmodule TrebyWeb.SchedulingLive.Booking do
  use TrebyWeb, :live_view

  alias Treby.{Availability, Interviews, Calendar}

  def mount(%{"tenant_slug" => _slug, "token" => token}, _session, socket) do
    case Interviews.get_booking_token(token) do
      nil ->
        {:ok,
         socket
         |> assign(valid: false, confirmed: false, token: nil)
         |> assign(page_title: "Invalid Booking Link")}

      booking_token ->
        interviewer = booking_token.interviewer
        date_range = %{from: Date.utc_today(), to: Date.add(Date.utc_today(), 13)}

        slots =
          if interviewer do
            case Availability.compute_slots(interviewer.id, date_range) do
              slots when is_list(slots) -> slots
              {:error, _} -> []
            end
          else
            []
          end

        {:ok,
         socket
         |> assign(valid: true, confirmed: false, token: booking_token)
         |> assign(interviewer: interviewer)
         |> assign(application: booking_token.application)
         |> assign(tenant: booking_token.tenant)
         |> assign(slots: slots)
         |> assign(selected_slot: nil)
         |> assign(selected_date: Date.utc_today())
         |> assign(page_title: "Schedule Interview")}
    end
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-50 py-12 px-4 sm:px-6 lg:px-8">
      <div class="max-w-2xl mx-auto">
        <%= if @confirmed do %>
          <div class="bg-white rounded-lg shadow p-8 text-center">
            <div class="mx-auto mb-4 flex h-16 w-16 items-center justify-center rounded-full bg-green-100">
              <.icon name="hero-check" class="h-8 w-8 text-green-600" />
            </div>
            <h1 class="text-2xl font-bold text-gray-900">Interview Scheduled!</h1>
            <p class="mt-2 text-gray-600">
              Your interview has been confirmed.
            </p>
            <div :if={@meet_link} class="mt-6">
              <a
                href={@meet_link}
                target="_blank"
                rel="noopener noreferrer"
                class="inline-flex items-center gap-2 px-6 py-3 bg-blue-600 text-white rounded-md hover:bg-blue-700 transition-colors"
              >
                <.icon name="hero-video-camera" class="h-5 w-5" /> Join Google Meet
              </a>
              <p class="mt-3 text-xs text-gray-500">
                A calendar invitation has been sent to your email.
              </p>
            </div>
            <div :if={!@meet_link} class="mt-6">
              <p class="text-sm text-gray-500">A calendar invitation has been sent to your email.</p>
            </div>
          </div>
        <% else %>
          <%= if @valid do %>
            <div class="text-center mb-8">
              <h1 class="text-2xl font-bold text-gray-900">Schedule your interview</h1>
              <p class="mt-2 text-gray-600">
                <%= if @interviewer do %>
                  with {@interviewer.name} for {@application.job.title}
                <% else %>
                  for {@application.job.title}
                <% end %>
              </p>
            </div>

            <div class="bg-white rounded-lg shadow p-6">
              <h2 class="text-lg font-semibold mb-4">Select a time slot</h2>

              <div class="flex items-center gap-4 mb-4">
                <button
                  phx-click="prev_week"
                  class="px-3 py-1 border rounded hover:bg-gray-50"
                >
                  &larr; Prev
                </button>
                <span class="text-sm text-gray-600">
                  {Elixir.Calendar.strftime(@selected_date, "%B %d")} - {Date.add(@selected_date, 6)
                  |> Elixir.Calendar.strftime("%B %d, %Y")}
                </span>
                <button
                  phx-click="next_week"
                  class="px-3 py-1 border rounded hover:bg-gray-50"
                >
                  Next &rarr;
                </button>
              </div>

              <div :if={@slots == []} class="text-center py-8">
                <p class="text-gray-500 text-sm">No available slots for this period</p>
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
                        else: "border-gray-200 hover:border-blue-300"
                      )
                    ]}
                  >
                    {slot.start |> Elixir.Calendar.strftime("%a %H:%M")}
                  </button>
                <% end %>
              </div>

              <%= if @selected_slot do %>
                <div class="mt-6 pt-6 border-t">
                  <p class="text-sm text-gray-600">
                    Selected:
                    <strong>
                      {Elixir.Calendar.strftime(@selected_slot.start, "%B %d, %Y at %H:%M UTC")}
                    </strong>
                  </p>
                  <button
                    phx-click="confirm_booking"
                    class="mt-4 w-full px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700"
                  >
                    Confirm Booking
                  </button>
                </div>
              <% end %>
            </div>
          <% else %>
            <div class="bg-white rounded-lg shadow p-8 text-center">
              <h1 class="text-xl font-bold text-gray-900">Invalid or Expired Link</h1>
              <p class="mt-2 text-gray-600">
                This scheduling link has expired or has already been used.
              </p>
              <p class="mt-2 text-sm text-gray-500">
                Please contact the recruiter for a new link.
              </p>
            </div>
          <% end %>
        <% end %>
      </div>
    </div>
    """
  end

  def handle_event("select_slot", %{"start" => start_iso}, socket) do
    {:ok, start_dt, _} = DateTime.from_iso8601(start_iso)
    slot = Enum.find(socket.assigns.slots, &(&1.start == start_dt))

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

  def handle_event("confirm_booking", _, socket) do
    %{selected_slot: slot, token: token, application: app, interviewer: interviewer} =
      socket.assigns

    unless slot do
      {:noreply, socket}
    else
      # Create Google Calendar event with Meet link
      case Calendar.create_event_with_meet(
             interviewer.id,
             %{
               summary: "Interview with #{app.candidate.name} - #{app.job.title}",
               description: "Scheduled via Treby self-scheduling",
               start_at: slot.start,
               end_at: slot.end,
               timezone: "UTC"
             },
             [app.candidate.email]
           ) do
        {:ok, event_result} ->
          attrs = %{
            start_at_utc: slot.start,
            end_at_utc: slot.end,
            duration_minutes: 30,
            interviewer_id: interviewer.id,
            application_id: app.id,
            tenant_id: token.tenant_id,
            video_conf_url: event_result.meet_link,
            google_event_id: event_result.event_id
          }

          case Interviews.schedule_interview(attrs) do
            {:ok, _event} ->
              Interviews.use_booking_token(token)

              {:noreply,
               socket
               |> assign(confirmed: true, meet_link: event_result.meet_link)
               |> put_flash(:info, "Interview scheduled!")}

            {:error, changeset} ->
              errors = Ecto.Changeset.traverse_errors(changeset, fn {msg, _} -> msg end)

              if Keyword.has_key?(errors, :interviewer_id) do
                refreshed_slots = recompute_slots(socket, socket.assigns.selected_date)

                {:noreply,
                 socket
                 |> assign(slots: refreshed_slots, selected_slot: nil)
                 |> put_flash(
                   :error,
                   "That time slot is no longer available. Please choose another."
                 )}
              else
                {:noreply, put_flash(socket, :error, "Failed to schedule interview")}
              end
          end

        {:error, _reason} ->
          {:noreply,
           socket
           |> assign(selected_slot: nil)
           |> put_flash(:error, "Failed to create calendar event. Please try again.")}
      end
    end
  end

  defp recompute_slots(socket, new_date) do
    date_range = %{from: new_date, to: Date.add(new_date, 6)}

    case Availability.compute_slots(socket.assigns.interviewer.id, date_range) do
      slots when is_list(slots) -> slots
      {:error, _} -> socket.assigns.slots
    end
  end
end
