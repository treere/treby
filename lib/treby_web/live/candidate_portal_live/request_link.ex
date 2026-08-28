defmodule TrebyWeb.CandidatePortalLive.RequestLink do
  use TrebyWeb, :live_view

  alias Treby.Tenants

  @impl true
  def mount(%{"tenant_slug" => slug}, _session, socket) do
    tenant = Tenants.get_tenant_by_slug!(slug)

    {:ok,
     socket
     |> assign(:tenant, tenant)
     |> assign(:page_title, "Access Portal")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen flex items-center justify-center bg-gray-50 dark:bg-gray-900 px-4">
      <div class="max-w-md w-full space-y-8">
        <div>
          <h2 class="mt-6 text-center text-3xl font-bold text-gray-900 dark:text-white">
            Access your portal
          </h2>
          <p class="mt-2 text-center text-sm text-gray-600 dark:text-gray-400">
            Enter your email to receive a one-time login code
          </p>
        </div>

        <.form
          for={%{}}
          action={~p"/#{@tenant.slug}/portal/login"}
          method="post"
          class="mt-8 space-y-6"
        >
          <div>
            <label for="email" class="sr-only">Email address</label>
            <input
              id="email"
              name="email"
              type="email"
              required
              class="appearance-none rounded-md relative block w-full px-3 py-2 border border-gray-300 dark:border-gray-600 placeholder-gray-500 dark:placeholder-gray-400 text-gray-900 dark:text-white bg-white dark:bg-gray-800 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm"
              placeholder="Email address"
            />
          </div>

          <div>
            <button
              type="submit"
              class="group relative w-full flex justify-center py-2 px-4 border border-transparent text-sm font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
            >
              Send login code
            </button>
          </div>
        </.form>
      </div>
    </div>
    """
  end
end
