defmodule Phylax.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      Phylax.Repo,
      ExEsi.Cache.MapStore,
      # Start Discord Systems
      Nosedrum.Storage.ETS,
      Phylax.Discord.ConsumerSupervisor,
      # Start the Telemetry supervisor
      PhylaxWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Phylax.PubSub},
      # Start Killbot Systems
      {Registry, keys: :unique, name: Phylax.Killbot.WorkerRegistry},
      Phylax.Killbot.WorkerSupervisor,
      Phylax.Killbot.Manager,
      # Start Pathfinder Systems
      Phylax.Pathfinder.Supervisor,
      # Start Zkillboard websocket
      Phylax.Zkillboard.RedisqClient,
      # Start the Endpoint (http/https)
      PhylaxWeb.Endpoint
      # Start a worker by calling: Phylax.Worker.start_link(arg)
      # {Phylax.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Phylax.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    PhylaxWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
