defmodule TrebyWeb.CandidatePortalLive.Verify do
  use TrebyWeb, :live_view

  alias Treby.Tenants

  @impl true
  def mount(%{"tenant_slug" => slug}, session, socket) do
    tenant = Tenants.get_tenant_by_slug!(slug)
    email = session["otp_email"]

    {:ok,
     socket
     |> assign(:tenant, tenant)
     |> assign(:email, email)
     |> assign(:has_email?, is_binary(email))
     |> assign(:page_title, "Enter your code")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen flex items-center justify-center bg-gray-50 dark:bg-gray-900 px-4">
      <div class="max-w-md w-full space-y-8">
        <div>
          <h2 class="mt-6 text-center text-3xl font-bold text-gray-900 dark:text-white">
            Enter your login code
          </h2>

          <%= if @has_email? do %>
            <p class="mt-2 text-center text-sm text-gray-600 dark:text-gray-400">
              We sent a 6-digit code to {@email}
            </p>
          <% else %>
            <p class="mt-2 text-center text-sm text-gray-600 dark:text-gray-400">
              Enter your email to receive a login code
            </p>
          <% end %>
        </div>

        <%= if @has_email? do %>
          <.form
            for={%{}}
            action={~p"/#{@tenant.slug}/portal/verify"}
            method="post"
            class="mt-8 space-y-6"
          >
            <div>
              <label for="code" class="sr-only">Login code</label>
              <input
                id="code"
                name="code"
                type="text"
                inputmode="numeric"
                maxlength="6"
                pattern="\d{6}"
                autocomplete="one-time-code"
                required
                class="appearance-none rounded-md relative block w-full px-3 py-2 border border-gray-300 dark:border-gray-600 placeholder-gray-500 dark:placeholder-gray-400 text-gray-900 dark:text-white bg-white dark:bg-gray-800 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm text-center text-lg tracking-widest"
                placeholder="000000"
              />
            </div>

            <div>
              <button
                type="submit"
                class="group relative w-full flex justify-center py-2 px-4 border border-transparent text-sm font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
              >
                Verify code
              </button>
            </div>
          </.form>

          <.form
            for={%{}}
            action={~p"/#{@tenant.slug}/portal/login"}
            method="post"
            class="text-center"
          >
            <input type="hidden" name="email" value={@email} />
            <button
              type="submit"
              class="text-sm font-medium text-blue-600 hover:text-blue-500"
            >
              Resend code
            </button>
          </.form>
        <% else %>
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
        <% end %>
      </div>
    </div>
    """
  end
end
