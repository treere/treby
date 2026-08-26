defmodule TrebyWeb.CandidatePortalLive.Settings do
  use TrebyWeb, :live_view

  alias Treby.CandidatePortal

  @impl true
  def mount(%{"tenant_slug" => slug}, session, socket) do
    candidate_id = session["candidate_id"]
    candidate = Treby.Repo.get!(Treby.Candidates.Candidate, candidate_id)
    tenant = Treby.Tenants.get_tenant_by_slug!(slug)
    prefs = CandidatePortal.get_notification_preferences(candidate)

    {:ok,
     socket
     |> assign(:candidate, candidate)
     |> assign(:current_tenant, tenant)
     |> assign(:current_candidate, candidate)
     |> assign(:preferences, prefs)
     |> assign(:page_title, "Settings")}
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
     |> put_flash(:info, "Preferences saved")}
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
        <h1 class="text-2xl font-bold text-gray-900 dark:text-white mb-6">Settings</h1>

        <div class="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 p-6">
          <h2 class="text-lg font-medium text-gray-900 dark:text-white mb-4">
            Notification Preferences
          </h2>

          <div class="space-y-4">
            <%= for {key, label} <- [
            {"new_message", "New messages"},
            {"status_change", "Status changes"},
            {"interview_update", "Interview updates"},
            {"important_only", "Important notifications only"}
          ] do %>
              <div class="flex items-center justify-between">
                <span class="text-sm text-gray-700 dark:text-gray-300">{label}</span>
                <button
                  phx-click="toggle_preference"
                  phx-value-key={key}
                  class={[
                    "relative inline-flex h-6 w-11 flex-shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors duration-200 ease-in-out focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2",
                    @preferences[key] && "bg-blue-600",
                    !@preferences[key] && "bg-gray-200 dark:bg-gray-700"
                  ]}
                >
                  <span class={[
                    "pointer-events-none inline-block h-5 w-5 transform rounded-full bg-white shadow ring-0 transition duration-200 ease-in-out",
                    @preferences[key] && "translate-x-5",
                    !@preferences[key] && "translate-x-0"
                  ]} />
                </button>
              </div>
            <% end %>
          </div>
        </div>
      </div>
    </Layouts.candidate_portal>
    """
  end
end
