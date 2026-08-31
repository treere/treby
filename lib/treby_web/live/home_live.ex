defmodule TrebyWeb.HomeLive do
  use TrebyWeb, :live_view

  alias TrebyWeb.Layouts

  def mount(_params, session, socket) do
    socket = set_locale_from_session(socket, session)
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-base-100">
      <Layouts.flash_group flash={@flash} />

      <%!-- Header --%>
      <header class="absolute inset-x-0 top-0 z-10">
        <nav class="flex items-center justify-between p-6 lg:px-8" aria-label={gettext("Global")}>
          <div class="flex lg:flex-1">
            <.link navigate={~p"/"} class="-m-1.5 p-1.5">
              <span class="sr-only">Treby</span>
              <span class="text-2xl font-bold text-blue-600">Treby</span>
            </.link>
          </div>
          <div class="flex items-center gap-x-4">
            <Layouts.theme_toggle />
            <Layouts.locale_switcher locale={@locale} />
            <.link
              navigate={~p"/careers"}
              id="home-careers-link"
              class="text-sm/6 font-semibold text-base-content hover:text-blue-600 transition-colors"
            >
              {gettext("Careers")}
            </.link>
            <.link
              navigate={~p"/login"}
              class="text-sm/6 font-semibold text-base-content hover:text-blue-600 transition-colors"
            >
              {gettext("Log in")}
            </.link>
            <.button
              navigate={~p"/register"}
              variant="primary"
              class="rounded-full"
            >
              {gettext("Get started")}
            </.button>
          </div>
        </nav>
      </header>

      <%!-- Hero section --%>
      <div class="relative isolate pt-14">
        <div
          class="absolute inset-x-0 -top-40 -z-10 transform-gpu overflow-hidden blur-3xl sm:-top-80"
          aria-hidden="true"
        >
          <div
            class="relative left-[calc(50%-11rem)] aspect-[1155/678] w-[36.125rem] -translate-x-1/2 rotate-[30deg] bg-gradient-to-tr from-blue-400 to-blue-600 opacity-30 sm:left-[calc(50%-30rem)] sm:w-[72.1875rem]"
            style="clip-path: polygon(74.1% 44.1%, 100% 61.6%, 97.5% 26.9%, 85.5% 0.1%, 80.7% 2%, 72.5% 32.5%, 60.2% 62.4%, 52.4% 68.1%, 47.5% 58.3%, 45.2% 34.5%, 27.5% 76.7%, 0.1% 64.9%, 17.9% 100%, 27.6% 76.8%, 76.1% 97.7%, 74.1% 44.1%)"
          >
          </div>
        </div>
        <div class="py-24 sm:py-32 lg:pb-40">
          <div class="mx-auto max-w-7xl px-6 lg:px-8">
            <div class="mx-auto max-w-2xl text-center">
              <h1 class="text-balance text-5xl font-semibold tracking-tight text-base-content sm:text-7xl">
                {gettext("Hire smarter with Treby")}
              </h1>
              <p class="mt-8 text-pretty text-lg font-medium text-base-content/50 sm:text-xl/8">
                {gettext(
                  "Streamline your hiring process from job posting to offer letter. Manage candidates, schedule interviews, and track your pipeline — all in one place."
                )}
              </p>
              <div class="mt-10 flex items-center justify-center gap-x-6">
                <.button
                  navigate={~p"/register"}
                  variant="primary"
                  size="lg"
                  class="rounded-full"
                >
                  {gettext("Get started free")}
                </.button>
                <.link
                  navigate={~p"/login"}
                  class="text-sm/6 font-semibold text-base-content hover:text-blue-600 transition-colors"
                >
                  {gettext("Log in")} <span aria-hidden="true">&rarr;</span>
                </.link>
              </div>
            </div>
          </div>
        </div>
      </div>

      <%!-- Feature section --%>
      <div class="bg-base-200 py-24 sm:py-32">
        <div class="mx-auto max-w-7xl px-6 lg:px-8">
          <div class="mx-auto max-w-2xl text-center">
            <h2 class="text-base font-semibold leading-7 text-blue-600">
              {gettext("Everything you need")}
            </h2>
            <p class="mt-2 text-3xl font-bold tracking-tight text-base-content sm:text-4xl">
              {gettext("A better way to hire")}
            </p>
            <p class="mt-6 text-lg leading-8 text-base-content/70">
              {gettext(
                "From posting jobs to extending offers, Treby gives you the tools to find and hire the best talent efficiently."
              )}
            </p>
          </div>
          <div class="mx-auto mt-16 max-w-2xl sm:mt-20 lg:mt-24 lg:max-w-none">
            <dl class="grid max-w-xl grid-cols-1 gap-x-8 gap-y-16 lg:max-w-none lg:grid-cols-3">
              <div class="flex flex-col">
                <dt class="flex items-center gap-x-3 text-base font-semibold leading-7 text-base-content">
                  <.icon name="hero-briefcase" class="h-5 w-5 flex-none text-blue-600" />
                  {gettext("Job Management")}
                </dt>
                <dd class="mt-4 flex flex-auto flex-col text-base leading-7 text-base-content/70">
                  <p class="flex-auto">
                    {gettext(
                      "Create and manage job postings with custom fields, salary ranges, and department assignments. Track applicants through your pipeline."
                    )}
                  </p>
                </dd>
              </div>
              <div class="flex flex-col">
                <dt class="flex items-center gap-x-3 text-base font-semibold leading-7 text-base-content">
                  <.icon name="hero-users" class="h-5 w-5 flex-none text-blue-600" />
                  {gettext("Candidate Tracking")}
                </dt>
                <dd class="mt-4 flex flex-auto flex-col text-base leading-7 text-base-content/70">
                  <p class="flex-auto">
                    {gettext(
                      "Keep all candidate information in one place. Track resumes, notes, interview feedback, and communication history."
                    )}
                  </p>
                </dd>
              </div>
              <div class="flex flex-col">
                <dt class="flex items-center gap-x-3 text-base font-semibold leading-7 text-base-content">
                  <.icon name="hero-calendar" class="h-5 w-5 flex-none text-blue-600" />
                  {gettext("Interview Scheduling")}
                </dt>
                <dd class="mt-4 flex flex-auto flex-col text-base leading-7 text-base-content/70">
                  <p class="flex-auto">
                    {gettext(
                      "Schedule interviews with integrated calendar support. Candidates can self-schedule using your custom booking page."
                    )}
                  </p>
                </dd>
              </div>
            </dl>
          </div>
        </div>
      </div>

      <%!-- Footer --%>
      <footer class="bg-base-100" aria-labelledby="footer-heading">
        <h2 id="footer-heading" class="sr-only">{gettext("Footer")}</h2>
        <div class="mx-auto max-w-7xl px-6 pb-8 pt-16 sm:pt-24 lg:px-8">
          <div class="xl:grid xl:grid-cols-3 xl:gap-8">
            <div>
              <span class="text-2xl font-bold text-blue-600">Treby</span>
              <p class="mt-4 text-sm leading-6 text-base-content/70">
                {gettext("Modern applicant tracking for growing teams.")}
              </p>
            </div>
            <div class="mt-10 xl:mt-0">
              <h3 class="text-sm font-semibold leading-6 text-base-content">
                {gettext("Discover")}
              </h3>
              <ul role="list" class="mt-4 space-y-3">
                <li>
                  <.link
                    navigate={~p"/careers"}
                    id="footer-careers-link"
                    class="text-sm leading-6 text-base-content/70 hover:text-blue-600"
                  >
                    {gettext("Careers")}
                  </.link>
                </li>
              </ul>
            </div>
          </div>
          <div class="mt-16 border-t border-gray-900/10 pt-8 sm:mt-20 lg:mt-24">
            <p class="text-xs/6 text-base-content/70">
              &copy; {DateTime.utc_now().year} Treby. {gettext("All rights reserved")}
            </p>
          </div>
        </div>
      </footer>
    </div>
    """
  end
end
