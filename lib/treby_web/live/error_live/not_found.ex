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
        <h1 class="text-2xl font-bold text-base-content mb-2">
          {gettext("Page not found")}
        </h1>
        <p class="text-base-content/70 mb-8 max-w-md">
          {gettext("The page or entity you're looking for doesn't exist or has been removed.")}
        </p>
        <div class="flex gap-4">
          <.link
            navigate={~p"/app/jobs"}
            class="inline-flex items-center px-5 py-2.5 rounded-lg bg-blue-600 text-white text-sm font-medium hover:bg-blue-700 transition-colors"
          >
            {gettext("Back to Jobs")}
          </.link>
          <.link
            navigate={~p"/app"}
            class="inline-flex items-center px-5 py-2.5 rounded-lg border border-base-300 text-base-content text-sm font-medium hover:bg-base-100 transition-colors"
          >
            {gettext("Go to Dashboard")}
          </.link>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
