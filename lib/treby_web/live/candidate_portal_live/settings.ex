defmodule TrebyWeb.CandidatePortalLive.Settings do
  use TrebyWeb, :live_view

  alias Treby.CandidatePortal

  @impl true
  def mount(%{"tenant_slug" => slug}, session, socket) do
    candidate_id = session["candidate_id"]
    candidate = Treby.Repo.get!(Treby.Candidates.Candidate, candidate_id)
    tenant = Treby.Tenants.get_tenant_by_slug!(slug)

    if tenant.id != candidate.tenant_id do
      real_tenant = Treby.Repo.get!(Treby.Tenants.Tenant, candidate.tenant_id)

      {:ok,
       socket
       |> put_flash(:error, gettext("Wrong workspace. Redirected to your portal."))
       |> redirect(to: "/#{real_tenant.slug}/portal/settings")}
    else
      prefs = CandidatePortal.get_notification_preferences(candidate)

      {:ok,
       socket
       |> assign(:candidate, candidate)
       |> assign(:current_tenant, tenant)
       |> assign(:current_candidate, candidate)
       |> assign(:preferences, prefs)
       |> assign(:page_title, "Settings")}
    end
  end

  @impl true
  def handle_event("toggle_preference", %{"key" => key}, socket) do
    candidate = socket.assigns.candidate
    current = socket.assigns.preferences[key]
    CandidatePortal.set_notification_preference(candidate, key, !current)

    prefs = CandidatePortal.get_notification_preferences(candidate)

    {:noreply,
     socket
     |> assign(:preferences, prefs)
     |> put_flash(:info, gettext("Preferences saved"))}
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
        <.page_header title={gettext("Settings")} />

        <.card>
          <h2 class="text-lg font-medium text-zinc-900 dark:text-zinc-100 mb-4">
            Notification Preferences
          </h2>

          <div class="space-y-4">
            <%= for {key, label} <- [
            {"new_message", gettext("New messages")},
            {"status_change", gettext("Status changes")},
            {"interview_update", gettext("Interview updates")},
            {"important_only", gettext("Important notifications only")}
          ] do %>
              <div class="flex items-center justify-between">
                <span class="text-sm text-zinc-900 dark:text-zinc-100/80">{label}</span>
                <button
                  phx-click="toggle_preference"
                  phx-value-key={key}
                  class={[
                    "relative inline-flex h-6 w-11 flex-shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors duration-200 ease-in-out focus:outline-none focus:ring-2 focus:ring-primary focus:ring-offset-2",
                    @preferences[key] && "bg-primary",
                    !@preferences[key] && "bg-zinc-200 dark:bg-zinc-700"
                  ]}
                >
                  <span class={[
                    "pointer-events-none inline-block h-5 w-5 transform rounded-full bg-white dark:bg-zinc-800 shadow ring-0 transition duration-200 ease-in-out",
                    @preferences[key] && "translate-x-5",
                    !@preferences[key] && "translate-x-0"
                  ]} />
                </button>
              </div>
            <% end %>
          </div>
        </.card>
      </div>
    </Layouts.candidate_portal>
    """
  end
end
