defmodule TrebyWeb.CandidatePortalLive.Schedule do
  use TrebyWeb, :live_view

  alias Treby.{Availability, Interviews, Pipeline, Calendar, Repo}
  alias Treby.Calendar.Providers.Jitsi

  @impl true
  def mount(%{"tenant_slug" => slug}, session, socket) do
    candidate_id = session["candidate_id"]
    candidate = Repo.get!(Treby.Candidates.Candidate, candidate_id)
    tenant = Repo.get!(Treby.Tenants.Tenant, candidate.tenant_id)
    slug_tenant = Treby.Tenants.get_tenant_by_slug(slug)

    if slug_tenant && slug_tenant.id != candidate.tenant_id do
      {:ok,
       socket
       |> put_flash(:error, gettext("Wrong workspace. Redirected to your portal."))
       |> redirect(to: "/#{tenant.slug}/portal/schedule")}
    else
      do_mount(candidate, tenant, socket)
    end
  end

  defp do_mount(candidate, tenant, socket) do
    application = schedulable_application(candidate.id)

    socket =
      socket
      |> assign(:candidate, candidate)
      |> assign(:current_candidate, candidate)
      |> assign(:current_tenant, tenant)
      |> assign(:page_title, gettext("Schedule Interview"))

    if application do
      stage = Repo.preload(application, :pipeline_stage).pipeline_stage
      date_range = %{from: Date.utc_today(), to: Date.add(Date.utc_today(), 13)}
      {slots, examiners} = compute_slots(stage, date_range)

      {:ok,
       socket
       |> assign(:application, application)
       |> assign(:stage, stage)
       |> assign(:examiners, examiners)
       |> assign(:slots, slots)
       |> assign(:selected_slot, nil)
       |> assign(:selected_date, Date.utc_today())
       |> assign(:confirmed, false)
       |> assign(:meet_link, nil)}
    else
      {:ok,
       socket
       |> assign(:application, nil)
       |> assign(:confirmed, false)
       |> assign(:meet_link, nil)}
    end
  end

  @impl true
  def handle_event("select_slot", %{"start" => start_iso}, socket) do
    {:ok, start_dt, _} = DateTime.from_iso8601(start_iso)
    slot = Enum.find(socket.assigns.slots, &(DateTime.compare(&1.start, start_dt) == :eq))

    {:noreply, assign(socket, selected_slot: slot)}
  end

  def handle_event("prev_week", _, socket) do
    new_date = Date.add(socket.assigns.selected_date, -7)
    {slots, examiners} = recompute_slots(socket, new_date)

    {:noreply,
     assign(socket,
       selected_date: new_date,
       slots: slots,
       examiners: examiners,
       selected_slot: nil
     )}
  end

  def handle_event("next_week", _, socket) do
    new_date = Date.add(socket.assigns.selected_date, 7)
    {slots, examiners} = recompute_slots(socket, new_date)

    {:noreply,
     assign(socket,
       selected_date: new_date,
       slots: slots,
       examiners: examiners,
       selected_slot: nil
     )}
  end

  def handle_event("confirm_booking", _, socket) do
    %{selected_slot: slot, application: app, stage: stage} = socket.assigns

    unless slot do
      {:noreply, socket}
    else
      examiner_ids =
        if Map.has_key?(slot, :available_examiners) && slot.available_examiners != [] do
          slot.available_examiners
        else
          eligible = Pipeline.list_eligible_examiners(stage)
          Enum.map(eligible, & &1.user_id)
        end

      event_params = %{
        summary:
          gettext("Interview with %{candidate} - %{job}",
            candidate: app.candidate.name,
            job: app.job.title
          ),
        description: gettext("Scheduled via candidate portal self-scheduling"),
        start_at: slot.start,
        end_at: slot.end,
        timezone: "UTC"
      }

      base_attrs = %{
        start_at_utc: slot.start,
        end_at_utc: slot.end,
        duration_minutes: 30,
        examiner_ids: examiner_ids,
        application_id: app.id,
        tenant_id: app.tenant_id
      }

      case Calendar.resolve_meeting(examiner_ids) do
        {:calendar_event, owner_id, :google_meet} ->
          attendee_emails = examiner_emails(socket, examiner_ids) ++ [app.candidate.email]

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

              schedule_booking(socket, attrs, event_result.video_link)

            {:error, _reason} ->
              {:noreply,
               socket
               |> assign(selected_slot: nil)
               |> put_flash(:error, gettext("Failed to create calendar event. Please try again."))}
          end

        {:meeting_url, :jitsi} ->
          {:ok, meet_url} =
            Jitsi.create_meeting_link(%{tenant_slug: socket.assigns.current_tenant.slug})

          attrs = base_attrs |> Map.put(:video_conf_url, meet_url)
          schedule_booking(socket, attrs, meet_url)
      end
    end
  end

  defp schedule_booking(socket, attrs, meet_link) do
    case Interviews.schedule_interview(attrs) do
      {:ok, _event} ->
        {:noreply,
         socket
         |> assign(confirmed: true, meet_link: meet_link)
         |> put_flash(:info, gettext("Interview scheduled!"))}

      {:error, _changeset} ->
        {slots, _examiners} = recompute_slots(socket, socket.assigns.selected_date)

        {:noreply,
         socket
         |> assign(slots: slots, selected_slot: nil)
         |> put_flash(
           :error,
           gettext("That time slot is no longer available. Please choose another.")
         )}
    end
  end

  defp examiner_emails(socket, examiner_ids) do
    examiner_ids
    |> Enum.flat_map(fn user_id ->
      Enum.filter(socket.assigns.examiners, &(&1.user_id == user_id))
    end)
    |> Enum.map(& &1.user.email)
    |> Enum.reject(&is_nil/1)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.candidate_portal
      flash={@flash}
      current_tenant={@current_tenant}
      current_candidate={@current_candidate}
    >
      <div class="max-w-2xl mx-auto px-4 py-8">
        <%= if @confirmed do %>
          <.card class="text-center">
            <div class="mx-auto mb-4 flex h-16 w-16 items-center justify-center rounded-full bg-success/10">
              <.icon name="hero-check" class="h-8 w-8 text-success" />
            </div>
            <h1 class="text-2xl font-bold text-base-content">
              {gettext("Interview Scheduled!")}
            </h1>
            <p class="mt-2 text-base-content/60">
              {gettext(
                "Your interview has been confirmed. You can find the details in your messages."
              )}
            </p>
            <div :if={@meet_link} class="mt-6">
              <.button variant="primary" href={@meet_link} target="_blank">
                <.icon name="hero-video-camera" class="h-5 w-5" /> {meeting_label(@meet_link)}
              </.button>
            </div>
          </.card>
        <% else %>
          <%= if @application do %>
            <.page_header
              title={gettext("Schedule your interview")}
              subtitle={@application.job.title}
            />

            <.card>
              <h2 class="text-lg font-semibold mb-4 text-base-content">
                {gettext("Select a time slot")}
              </h2>

              <div class="flex items-center gap-4 mb-4">
                <.button variant="ghost" size="sm" phx-click="prev_week">
                  &larr; Prev
                </.button>
                <span class="text-sm text-base-content/60">
                  {Elixir.Calendar.strftime(@selected_date, "%B %d")} - {Date.add(@selected_date, 6)
                  |> Elixir.Calendar.strftime("%B %d, %Y")}
                </span>
                <.button variant="ghost" size="sm" phx-click="next_week">
                  {gettext("Next &rarr;")}
                </.button>
              </div>

              <div :if={@slots == []} class="text-center py-8">
                <.empty_state
                  icon="hero-calendar-days"
                  title={gettext("No available slots for this period")}
                  description={gettext("Try navigating to another week.")}
                />
              </div>

              <div :if={@slots != []} class="grid grid-cols-7 gap-2">
                <%= for slot <- @slots do %>
                  <button
                    phx-click="select_slot"
                    phx-value-start={slot.start |> DateTime.to_iso8601()}
                    class={[
                      "px-3 py-2 text-xs rounded border text-center transition-colors",
                      if(@selected_slot && @selected_slot.start == slot.start,
                        do: "border-primary bg-primary text-primary-content",
                        else: "border-base-300 hover:border-primary/50 bg-base-100"
                      )
                    ]}
                  >
                    {slot.start |> Elixir.Calendar.strftime("%a %H:%M")}
                    <%= if Map.has_key?(slot, :available_examiners) && slot.available_examiners != [] do %>
                      <div class="text-[10px] text-success mt-0.5">
                        {length(slot.available_examiners)} available
                      </div>
                    <% end %>
                  </button>
                <% end %>
              </div>

              <%= if @selected_slot do %>
                <div class="mt-6 pt-6 border-t border-base-300">
                  <p class="text-sm text-base-content/60">
                    {gettext("Selected:")}
                    <strong class="text-base-content ml-1">
                      {Elixir.Calendar.strftime(@selected_slot.start, "%B %d, %Y at %H:%M UTC")}
                    </strong>
                  </p>
                  <.button
                    phx-click="confirm_booking"
                    variant="primary"
                    class="mt-4 w-full"
                  >
                    {gettext("Confirm Booking")}
                  </.button>
                </div>
              <% end %>
            </.card>
          <% else %>
            <.card class="text-center">
              <h1 class="text-xl font-bold text-base-content">
                {gettext("Nothing to schedule")}
              </h1>
              <p class="mt-2 text-base-content/60">
                {gettext("You don't have any application in an interview stage right now.")}
              </p>
            </.card>
          <% end %>
        <% end %>
      </div>
    </Layouts.candidate_portal>
    """
  end

  defp meeting_label(link) when is_binary(link) do
    if String.contains?(link, "meet.jit.si"),
      do: gettext("Join Jitsi Meeting"),
      else: gettext("Join Meeting")
  end

  defp meeting_label(_), do: gettext("Join Meeting")

  defp schedulable_application(candidate_id) do
    import Ecto.Query

    Treby.Pipeline.Application
    |> where([a], a.candidate_id == ^candidate_id)
    |> preload([:pipeline_stage, :job, :candidate])
    |> Repo.all()
    |> Enum.find(&(&1.pipeline_stage && &1.pipeline_stage.stage_type == "interview"))
  end

  defp compute_slots(stage, date_range) do
    eligible = Pipeline.list_eligible_examiners(stage)
    examiner_ids = Enum.map(eligible, & &1.user_id)
    min_examiners = stage.min_examiners || 1

    cond do
      length(eligible) < min_examiners ->
        {[], eligible}

      min_examiners > 1 ->
        case Availability.compute_overlapping_slots(examiner_ids, min_examiners, date_range) do
          slots when is_list(slots) -> {slots, eligible}
          {:error, _} -> {[], eligible}
        end

      true ->
        [first | _] = eligible

        case Availability.compute_slots(first.user_id, date_range) do
          slots when is_list(slots) -> {slots, eligible}
          {:error, _} -> {[], eligible}
        end
    end
  end

  defp recompute_slots(socket, new_date) do
    date_range = %{from: new_date, to: Date.add(new_date, 6)}
    compute_slots(socket.assigns.stage, date_range)
  end
end
