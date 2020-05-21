defmodule Phylax.Pathfinder.Manager do
  @moduledoc false

  use GenServer
  require Logger
  alias Phylax.Pathfinder, as: PF

  @name __MODULE__

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: @name)
  end

  # Server Callbacks

  def init(initial_state) do
    {:ok, initial_state, {:continue, :load_workers}}
  end

  def handle_continue(:load_workers, _state) do
    chains = PF.get_watched_chains()

    map_ids = map_ids(chains)
    chain_ids = chain_ids(chains)

    populate_maps(map_ids)
    populate_chains(chain_ids)
    start_chain_killbots(chains)

    {:noreply, %{maps: map_ids, chains: chain_ids}}
  end

  defp map_ids(chains) do
    chains
    |> Enum.map(& &1.map_id)
    |> Enum.uniq()
  end

  defp chain_ids(chains) do
    chains
    |> Enum.map(&{&1.map_id, &1.root_system_id})
    |> Enum.uniq()
  end

  defp populate_maps(map_ids) do
    for map_id <- map_ids do
      Logger.debug("Populating map #{inspect(map_id)}")
      PF.Map.Worker.start_tracking_map(map_id)
    end
  end

  defp populate_chains(chain_ids) do
    for {map_id, root_system_id} <- chain_ids do
      Logger.debug("Populating Chain {#{map_id}, #{root_system_id}}")
      PF.Chain.Worker.start_tracking_chain({map_id, root_system_id})
    end
  end

  defp start_chain_killbots(chains) do
    for chain <- chains do
      PF.Chain.Killbot.start_link(channel: chain.channel_id)
    end
  end
end
