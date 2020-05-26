defmodule Phylax.Pathfinder.Supervisor do
  use Supervisor

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    children = [
      Phylax.Pathfinder.Repo,
      {Registry, keys: :unique, name: Phylax.Pathfinder.WorkerRegistry},
      Phylax.Pathfinder.Chain.KillbotSupervisor,
      Phylax.Pathfinder.Watchlist.Supervisor,
      Phylax.Pathfinder.Map.Worker,
      Phylax.Pathfinder.Chain.Worker,
      Phylax.Pathfinder.Manager
    ]

    Supervisor.init(children, strategy: :rest_for_one)
  end
end
