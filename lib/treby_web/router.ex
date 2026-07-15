defmodule TrebyWeb.Router do
  use TrebyWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {TrebyWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :require_auth do
    plug TrebyWeb.Plugs.Auth
  end

  # Public routes
  scope "/", TrebyWeb do
    pipe_through :browser

    get "/", PageController, :home
    live "/:tenant_slug/careers", CareersLive.Index
    live "/:tenant_slug/careers/:job_id", CareersLive.Show
    live "/:tenant_slug/careers/:job_id/apply", CareersLive.Apply
    get "/invite/:token", InviteController, :show
    post "/invite/:token", InviteController, :create
  end

  # Auth routes (no auth required)
  scope "/", TrebyWeb do
    pipe_through :browser

    get "/login", SessionController, :new
    post "/session", SessionController, :create
    delete "/session", SessionController, :delete
    get "/register", RegistrationController, :new
    post "/register", RegistrationController, :create
  end

  # Authenticated routes
  scope "/app", TrebyWeb do
    pipe_through [:browser, :require_auth]

    live "/", DashboardLive
    live "/jobs", JobsLive.Index
    live "/jobs/:id", JobsLive.Show
    live "/candidates", CandidatesLive.Index
    live "/candidates/:id", CandidatesLive.Show
    live "/pipeline/:job_id", PipelineLive.Index
    live "/analytics", AnalyticsLive.Index
    live "/settings", SettingsLive.Index
    live "/settings/pipeline", SettingsLive.Pipeline
    live "/settings/fields", SettingsLive.Fields
    live "/settings/team", SettingsLive.Team
    live "/settings/branding", SettingsLive.Branding

    get "/applications/:id/resume", ResumeController, :show
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:treby, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: TrebyWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
