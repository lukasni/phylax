defmodule Phylax.Pathfinder.Chain.Worker do
  @moduledoc false

  use GenServer
  require Logger
  alias Phylax.Pathfinder

  @name __MODULE__

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: @name)
  end

  def get_connections(chain_id) do
    GenServer.call(@name, {:get_connections, chain_id})
  end

  def start_tracking_chain(chain_id) do
    GenServer.call(@name, {:add_chain, chain_id})
  end

  def init(opts) do
    Logger.debug("Starting map worker with options #{inspect(opts)}")
    Phylax.subscribe(:pathfinder)

    {:ok, %{}}
  end

  def handle_call({:get_connections, {map_id, root_system_id}}, _from, state) do
    {:reply, get_in(state, [map_id, root_system_id]), state}
  end

  def handle_call({:add_chain, {map_id, root_system_id}}, _from, state) do
    map = Pathfinder.Map.Worker.get_map(map_id)
    connections = Pathfinder.Chain.connected_systems(map, root_system_id)
    #new_state = put_in(state, [map_id, root_system_id], connections)
    new_state = Map.update(state, map_id, %{root_system_id => connections}, &Map.put(&1, root_system_id, connections))

    {:reply, connections, new_state}
  end

  def handle_info({:map_changed, %{map_id: map_id} = map}, state) when is_map_key(state, map_id) do
    chains = Map.get(state, map_id)

    new_chains =
      chains
      |> Enum.reduce(chains, fn {root_system_id, connections}, acc ->
        Map.put(acc, root_system_id, update_chain(map, root_system_id, connections))
      end)

    {:noreply, Map.put(state, map_id, new_chains)}
  end

  def handle_info(_, state) do
    {:noreply, state}
  end

  defp update_chain(map, root_system_id, connections) do
    new_connections = Pathfinder.Chain.connected_systems(map.graph, root_system_id)

    case Pathfinder.Chain.check_updated_connections(connections, new_connections) do
      {:updated, changes} ->
        msg =
          changes
          |> Map.put(:chain_id, {map.map_id, root_system_id})

        Pathfinder.broadcast({:chain_update, msg})

      :unchanged ->
        :noop
    end

    new_connections
  end
end
