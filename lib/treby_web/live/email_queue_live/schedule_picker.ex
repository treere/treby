defmodule TrebyWeb.EmailQueueLive.SchedulePicker do
  use TrebyWeb, :live_component

  def mount(socket) do
    now = DateTime.utc_now()

    socket =
      assign(socket,
        mode: :now,
        scheduled_at: nil,
        jitter_minutes: 5,
        date: Calendar.strftime(now, "%Y-%m-%d"),
        time: "09:00"
      )

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="space-y-4">
      <div class="flex gap-4">
        <label class="flex items-center gap-2 cursor-pointer">
          <input
            type="radio"
            name={@prefix <> "[mode]"}
            value="now"
            checked={@mode == "now"}
            phx-click="set_mode"
            phx-value-mode="now"
            phx-target={@myself}
            class="radio radio-sm"
          />
          <span class="text-sm font-medium text-gray-700">Send now</span>
        </label>
        <label class="flex items-center gap-2 cursor-pointer">
          <input
            type="radio"
            name={@prefix <> "[mode]"}
            value="schedule"
            checked={@mode == "schedule"}
            phx-click="set_mode"
            phx-value-mode="schedule"
            phx-target={@myself}
            class="radio radio-sm"
          />
          <span class="text-sm font-medium text-gray-700">Schedule for later</span>
        </label>
      </div>

      <%= if @mode == "schedule" do %>
        <div class="flex flex-wrap gap-2">
          <button
            type="button"
            phx-click="preset"
            phx-value-label="tomorrow_9"
            phx-target={@myself}
            class="px-3 py-1.5 text-sm font-medium rounded-lg border border-gray-300 hover:bg-blue-50 hover:border-blue-300 transition-colors"
          >
            Tomorrow 9:00
          </button>
          <button
            type="button"
            phx-click="preset"
            phx-value-label="tomorrow_14"
            phx-target={@myself}
            class="px-3 py-1.5 text-sm font-medium rounded-lg border border-gray-300 hover:bg-blue-50 hover:border-blue-300 transition-colors"
          >
            Tomorrow 14:00
          </button>
          <button
            type="button"
            phx-click="preset"
            phx-value-label="next_monday"
            phx-target={@myself}
            class="px-3 py-1.5 text-sm font-medium rounded-lg border border-gray-300 hover:bg-blue-50 hover:border-blue-300 transition-colors"
          >
            Next Monday
          </button>
        </div>

        <div class="grid grid-cols-2 gap-3">
          <div>
            <label class="block text-xs font-medium text-gray-600 mb-1">Date</label>
            <input
              type="date"
              name={@prefix <> "[scheduled_at_date]"}
              value={@date}
              phx-change="update_date"
              phx-target={@myself}
              class="input w-full"
            />
          </div>
          <div>
            <label class="block text-xs font-medium text-gray-600 mb-1">Time</label>
            <input
              type="time"
              name={@prefix <> "[scheduled_at_time]"}
              value={@time}
              phx-change="update_time"
              phx-target={@myself}
              class="input w-full"
            />
          </div>
        </div>

        <label class="flex items-center gap-2 cursor-pointer">
          <input
            type="checkbox"
            name={@prefix <> "[jitter]"}
            value="on"
            checked={@jitter_minutes > 0}
            phx-click="toggle_jitter"
            phx-target={@myself}
            class="checkbox checkbox-sm"
          />
          <span class="text-sm text-gray-600">
            Add randomness (<span class="font-medium">±<%= @jitter_minutes %> min</span>) so emails don't all arrive at the exact same time
          </span>
        </label>

        <input
          type="hidden"
          name={@prefix <> "[scheduled_at]"}
          value={serialize_scheduled_at(@scheduled_at)}
        />
        <input type="hidden" name={@prefix <> "[jitter_minutes]"} value={@jitter_minutes} />
      <% end %>
    </div>
    """
  end

  def handle_event("set_mode", %{"mode" => mode}, socket) do
    socket =
      if mode == "schedule" && is_nil(socket.assigns.scheduled_at) do
        dt = compute_tomorrow_9()

        assign(socket,
          mode: :schedule,
          scheduled_at: dt,
          date: Calendar.strftime(dt, "%Y-%m-%d"),
          time: "09:00"
        )
      else
        assign(socket, mode: String.to_existing_atom(mode))
      end

    {:noreply, socket}
  end

  def handle_event("preset", %{"label" => "tomorrow_9"}, socket) do
    dt = compute_tomorrow_9()

    {:noreply,
     assign(socket,
       scheduled_at: dt,
       mode: :schedule,
       date: Calendar.strftime(dt, "%Y-%m-%d"),
       time: "09:00"
     )}
  end

  def handle_event("preset", %{"label" => "tomorrow_14"}, socket) do
    dt = compute_tomorrow_14()

    {:noreply,
     assign(socket,
       scheduled_at: dt,
       mode: :schedule,
       date: Calendar.strftime(dt, "%Y-%m-%d"),
       time: "14:00"
     )}
  end

  def handle_event("preset", %{"label" => "next_monday"}, socket) do
    dt = compute_next_monday_9()

    {:noreply,
     assign(socket,
       scheduled_at: dt,
       mode: :schedule,
       date: Calendar.strftime(dt, "%Y-%m-%d"),
       time: "09:00"
     )}
  end

  def handle_event("update_date", %{"value" => date}, socket) do
    time = socket.assigns.time
    dt = build_datetime(date, time)
    {:noreply, assign(socket, date: date, scheduled_at: dt)}
  end

  def handle_event("update_time", %{"value" => time}, socket) do
    date = socket.assigns.date
    dt = build_datetime(date, time)
    {:noreply, assign(socket, time: time, scheduled_at: dt)}
  end

  def handle_event("toggle_jitter", _params, socket) do
    current = socket.assigns.jitter_minutes
    {:noreply, assign(socket, jitter_minutes: if(current > 0, do: 0, else: 5))}
  end

  defp compute_tomorrow_9 do
    tomorrow = Date.add(Date.utc_today(), 1)
    {:ok, dt} = DateTime.new(tomorrow, ~T[09:00:00], "Etc/UTC")
    dt
  end

  defp compute_tomorrow_14 do
    tomorrow = Date.add(Date.utc_today(), 1)
    {:ok, dt} = DateTime.new(tomorrow, ~T[14:00:00], "Etc/UTC")
    dt
  end

  defp compute_next_monday_9 do
    today = Date.utc_today()
    days_until_monday = (8 - Date.day_of_week(today)) |> rem(7)
    days_until_monday = if days_until_monday == 0, do: 7, else: days_until_monday
    next_monday = Date.add(today, days_until_monday)
    {:ok, dt} = DateTime.new(next_monday, ~T[09:00:00], "Etc/UTC")
    dt
  end

  defp build_datetime(date_str, time_str) do
    with {:ok, date} <- Date.from_iso8601(date_str),
         {:ok, time} <- Time.from_iso8601(time_str),
         {:ok, dt} <- DateTime.new(date, time, "Etc/UTC") do
      dt
    else
      _ -> nil
    end
  end

  defp serialize_scheduled_at(nil), do: ""
  defp serialize_scheduled_at(%DateTime{} = dt), do: Calendar.strftime(dt, "%Y-%m-%dT%H:%M:%SZ")
end
