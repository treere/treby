defmodule TrebyWeb.ErrorLive.NotFound do
  use TrebyWeb, :live_view

  def mount(_params, session, socket) do
    socket = set_locale_from_session(socket, session)
    {:ok, assign(socket, locale: socket.assigns.locale)}
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-zinc-50 dark:bg-zinc-800 flex flex-col">
      <Layouts.public_header locale={@locale} />

      <div class="flex-1 flex items-center justify-center px-4 py-24">
        <div class="max-w-md text-center">
          <p class="text-7xl font-bold text-orange-600 mb-4">404</p>
          <h1 class="text-2xl font-bold text-zinc-900 dark:text-zinc-100 mb-2">
            {gettext("Page not found")}
          </h1>
          <p class="text-zinc-500 dark:text-zinc-400 mb-8">
            {gettext("The page or entity you're looking for doesn't exist or has been removed.")}
          </p>
          <div class="flex flex-wrap gap-4 justify-center">
            <.button variant="primary" navigate={~p"/careers"}>
              {gettext("Browse all positions")}
            </.button>
            <.button variant="ghost" navigate={~p"/"}>
              {gettext("Go to homepage")}
            </.button>
          </div>
        </div>
      </div>

      <Layouts.public_footer />
    </div>
    """
  end
end
