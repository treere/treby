defmodule TrebyWeb.Router do
  use TrebyWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug TrebyWeb.Plugs.SetLocale
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

  pipeline :candidate_auth do
    plug TrebyWeb.Plugs.CandidateAuth
  end

  # Authenticated routes (before public catch-all to avoid route collisions)
  scope "/app", TrebyWeb do
    pipe_through [:browser, :require_auth]

    live_session :default,
      on_mount: [
        {TrebyWeb.Hooks.SetLocale, :set_locale}
      ] do
      live "/", DashboardLive
      live "/jobs", JobsLive.Index
      live "/jobs/:id/analytics", JobsLive.Analytics
      live "/jobs/:id", JobsLive.Show
      live "/candidates", CandidatesLive.Index
      live "/candidates/merge", CandidatesLive.Merge
      live "/candidates/compare", ComparisonLive.Index
      live "/candidates/:id", CandidatesLive.Show
      live "/pipeline/:job_id", PipelineLive.Index
      live "/analytics", AnalyticsLive.Index
      live "/schedule/:application_id", ScheduleLive.Index
      live "/interviews", InterviewsLive.Index
      live "/import", ImportLive.Index
      live "/messages-queue", MessagesQueueLive.Index

      get "/applications/:id/resume", ResumeController, :show
    end

    live_session :admin,
      on_mount: [
        {TrebyWeb.Hooks.SetLocale, :set_locale},
        {TrebyWeb.Hooks.RequireRole, %{role: "admin"}}
      ] do
      live "/settings", SettingsLive.Index
      live "/settings/pipeline", SettingsLive.Pipeline
      live "/settings/pipeline/:id", SettingsLive.PipelineStages
      live "/settings/fields", SettingsLive.Fields
      live "/settings/team", SettingsLive.Team
      live "/settings/branding", SettingsLive.Branding
      live "/settings/calendar", SettingsLive.Calendar
      live "/settings/availability", SettingsLive.Availability
      live "/settings/language", SettingsLive.Language
      live "/settings/scorecards", SettingsLive.Scorecards
      live "/settings/emails", SettingsLive.EmailTemplates
      live "/settings/sources", SettingsLive.Sources
      live "/settings/notifications", SettingsLive.Notifications
    end
  end

  # Auth routes (no auth required)
  scope "/", TrebyWeb do
    pipe_through :browser

    get "/locale/:locale", LocaleController, :set
    get "/login", SessionController, :new
    post "/session", SessionController, :create
    delete "/session", SessionController, :delete
    get "/register", RegistrationController, :new
    post "/register", RegistrationController, :create
    get "/register/verify", RegistrationController, :verify
    post "/register/verify", RegistrationController, :verify_code
    get "/reset-password", PasswordResetController, :new
    post "/reset-password", PasswordResetController, :create
    get "/reset-password/:token", PasswordResetController, :edit
    post "/reset-password/:token", PasswordResetController, :update
  end

  # Public routes (after authenticated routes to avoid collisions)
  scope "/", TrebyWeb do
    pipe_through :browser

    live "/", HomeLive
    live "/404", ErrorLive.NotFound
    live "/careers", CareersLive.GlobalIndex
    live "/:tenant_slug/careers", CareersLive.Index
    live "/:tenant_slug/careers/:job_id", CareersLive.Show
    live "/:tenant_slug/careers/:job_id/apply", CareersLive.Apply
    get "/invite/:token", InviteController, :show
    post "/invite/:token", InviteController, :create
    get "/terms", StaticPageController, :terms
    get "/privacy", StaticPageController, :privacy
  end

  # Candidate portal — public auth endpoints (OTP request + verification)
  scope "/:tenant_slug", TrebyWeb do
    pipe_through :browser

    live "/portal/login", CandidatePortalLive.RequestLink
    live "/portal/verify", CandidatePortalLive.Verify
    post "/portal/login", CandidateOtpController, :create
    post "/portal/verify", CandidateOtpController, :verify
  end

  # Candidate portal (authenticated)
  scope "/:tenant_slug", TrebyWeb do
    pipe_through [:browser, :candidate_auth]

    live "/portal", CandidatePortalLive.Index
    live "/portal/messages", CandidatePortalLive.Messages
    live "/portal/messages/:id", CandidatePortalLive.MessageThread
    live "/portal/schedule", CandidatePortalLive.Schedule
    live "/portal/settings", CandidatePortalLive.Settings
    delete "/portal/logout", CandidatePortalLogoutController, :delete
  end

  # Auth-required routes (for OAuth callbacks)
  scope "/auth", TrebyWeb do
    pipe_through [:browser, :require_auth]

    get "/google", GoogleAuthController, :new
    get "/google/callback", GoogleAuthController, :callback
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
