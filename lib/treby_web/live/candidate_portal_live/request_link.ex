defmodule TrebyWeb.CandidatePortalLive.RequestLink do
  use TrebyWeb, :live_view

  alias Treby.Tenants

  @impl true
  def mount(%{"tenant_slug" => slug}, _session, socket) do
    tenant = Tenants.get_tenant_by_slug!(slug)

    {:ok,
     socket
     |> assign(:tenant, tenant)
     |> assign(:page_title, gettext("Access Portal"))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen flex items-center justify-center bg-zinc-50 dark:bg-zinc-800 px-4">
      <div class="max-w-md w-full">
        <.card class="shadow-sm">
          <div class="text-center mb-6">
            <h2 class="text-3xl font-bold text-zinc-900 dark:text-zinc-100">
              Access your portal
            </h2>
            <p class="mt-2 text-sm text-zinc-500 dark:text-zinc-400">
              Enter your email to receive a one-time login code
            </p>
          </div>

          <.form
            for={%{}}
            action={~p"/#{@tenant.slug}/portal/login"}
            method="post"
            class="space-y-6"
          >
            <div>
              <label for="email" class="sr-only">{gettext("Email address")}</label>
              <input
                id="email"
                name="email"
                type="email"
                required
                class="input w-full"
                placeholder={gettext("Email address")}
              />
            </div>

            <div>
              <.button type="submit" variant="primary" class="w-full min-h-[44px]">
                Send login code
              </.button>
            </div>
          </.form>
          <p class="mt-4 text-center text-xs text-zinc-400 dark:text-zinc-500">
            {gettext(
              "Code valid 10 minutes — check spam folder, sender noreply@treby.app. You can request a new code after 60 seconds."
            )}
          </p>
        </.card>
      </div>
    </div>
    """
  end
end
