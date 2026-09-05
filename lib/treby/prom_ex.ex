defmodule Treby.PromEx do
  @moduledoc """
  PromEx module for Prometheus metrics.
  Collects Phoenix, Ecto, Oban, LiveView and BEAM metrics.
  Endpoint exposed via `PromEx.Plug` at `/metrics`.
  """

  use PromEx, otp_app: :treby

  alias PromEx.Plugins

  @impl true
  def plugins do
    [
      Plugins.Application,
      Plugins.Beam,
      {Plugins.Phoenix, router: TrebyWeb.Router, endpoint: TrebyWeb.Endpoint},
      {Plugins.Ecto, otp_app: :treby, repos: [Treby.Repo]},
      Plugins.Oban,
      Plugins.PhoenixLiveView
    ]
  end

  @impl true
  def dashboard_assigns do
    [
      datasource_id: "prometheus",
      otp_app: :treby
    ]
  end

  @impl true
  def dashboards do
    [{:prom_ex, "treby.json"}]
  end
end
