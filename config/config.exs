# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

# Helper to read env vars, treating empty strings as unset (so the
# default fallback is used). Use `env/1` when no default is wanted.
defmodule Treby.ConfigHelpers do
  @moduledoc false

  def env(var, default), do: if(present?(var), do: System.get_env(var), else: default)
  def env(var), do: if(present?(var), do: System.get_env(var), else: nil)
  def present?(var), do: match?(v when is_binary(v) and v != "", System.get_env(var))
end

config :treby,
  ecto_repos: [Treby.Repo],
  generators: [timestamp_type: :utc_datetime]

# Configure the endpoint
config :treby, TrebyWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: TrebyWeb.ErrorHTML, json: TrebyWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Treby.PubSub,
  live_view: [signing_salt: "OW3dVqeX"]

# Configure Oban
config :treby, Oban,
  engine: Oban.Engines.Basic,
  queues: [email: 10, messages: 10],
  repo: Treby.Repo

# Candidate portal auth
config :treby, Treby.CandidatePortal,
  otp_validity_minutes: 10,
  otp_resend_cooldown_seconds: 60,
  session_lifetime_hours: 4

# Configure the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :treby, Treby.Mailer, adapter: Swoosh.Adapters.Local

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.25.4",
  treby: [
    args:
      ~w(js/app.js --bundle --target=es2022 --outdir=../priv/static/assets/js --external:/fonts/* --external:/images/* --alias:@=.),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => [Path.expand("../deps", __DIR__), Mix.Project.build_path()]}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "4.1.12",
  treby: [
    args: ~w(
      --input=assets/css/app.css
      --output=priv/static/assets/css/app.css
    ),
    cd: Path.expand("..", __DIR__)
  ]

# Configure Elixir's Logger
config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Configure timezone database for availability calculations
config :elixir, :time_zone_database, Tzdata.TimeZoneDatabase

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Configure Gettext default locale
config :treby, TrebyWeb.Gettext, default_locale: "en"

# Configure S3 (RustFS in dev, any S3 provider in prod)
config :ex_aws,
  json_codec: Jason,
  http_client: ExAws.Request.Req

config :ex_aws, :s3,
  scheme: "http://",
  host: "localhost",
  port: 9000

# Google Calendar OAuth
config :treby,
  google_client_id: Treby.ConfigHelpers.env("GOOGLE_CLIENT_ID"),
  google_client_secret: Treby.ConfigHelpers.env("GOOGLE_CLIENT_SECRET")

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
