defmodule Caddishouse.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      Caddishouse.Repo,
      # Start the Telemetry supervisor
      CaddishouseWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Caddishouse.PubSub},
      # Start the Endpoint (http/https)
      CaddishouseWeb.Endpoint,
      {Oban, Application.fetch_env!(:caddishouse, Oban)},
      {Finch, name: CaddishouseFinch}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Caddishouse.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    CaddishouseWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
