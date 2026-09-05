defmodule TrebyWeb.ErrorLive.NotFound do
  use TrebyWeb, :live_view

  def mount(_params, session, socket) do
    socket = set_locale_from_session(socket, session)
    {:ok, assign(socket, locale: socket.assigns.locale)}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} locale={@locale}>
      <div class="max-w-7xl mx-auto px-4 py-24 flex flex-col items-center justify-center text-center">
        <p class="text-7xl font-bold text-blue-600 mb-4">404</p>
        <h1 class="text-2xl font-bold text-zinc-900 dark:text-zinc-100 mb-2">
          {gettext("Page not found")}
        </h1>
        <p class="text-zinc-500 dark:text-zinc-400 mb-8 max-w-md">
          {gettext("The page or entity you're looking for doesn't exist or has been removed.")}
        </p>
        <div class="flex gap-4">
          <.button navigate={~p"/app/jobs"} variant="primary">
            {gettext("Back to Jobs")}
          </.button>
          <.button navigate={~p"/app"} variant="ghost">
            {gettext("Go to Dashboard")}
          </.button>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
