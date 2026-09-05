defmodule Treby.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  alias Treby.Availability.ProviderCache

  @impl true
  def start(_type, _args) do
    children = [
      Treby.PromEx,
      Treby.Vault,
      TrebyWeb.Telemetry,
      Treby.Repo,
      {DNSCluster, query: Application.get_env(:treby, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Treby.PubSub},
      {Oban, Application.get_env(:treby, Oban)},
      ProviderCache,
      # Start a worker by calling: Treby.Worker.start_link(arg)
      # {Treby.Worker, arg},
      # Start to serve requests, typically the last entry
      TrebyWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Treby.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    TrebyWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
