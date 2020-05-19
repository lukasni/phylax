defmodule Phylax.Pathfinder.Chain.Worker do
  @moduledoc false

  use GenServer
  require Logger
  alias Phylax.Pathfinder

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: via_tuple(opts))
  end

  def get_connections(chain_id) do
    GenServer.call(via_tuple(chain_id), :get_connections)
  end

  def init(opts) do
    Logger.debug("Starting map worker with options #{inspect(opts)}")
    Phylax.subscribe(:pathfinder)

    state =
      opts
      |> Map.new()
      |> Map.put(:connections, [])

    {:ok, state, {:continue, :load_connections}}
  end

  def handle_call(:get_connections, _from, state) do
    {:reply, state.connections, state}
  end

  def handle_continue(:load_connections, state) do
    map = Pathfinder.Map.Worker.get_map(state.map_id)
    connections = Pathfinder.Chain.connected_systems(map, state.root_system_id)

    {:noreply, %{state | connections: connections}}
  end

  def handle_info({:map_changed, map}, state) do
    new_connections = Pathfinder.Chain.connected_systems(map.graph, state.root_system_id)

    case Pathfinder.Chain.check_updated_connections(state.connections, new_connections) do
      {:updated, changes} ->
        msg =
          changes
          |> Map.put(:chain_id, {state.map_id, state.root_system_id})

        Pathfinder.broadcast({:chain_update, msg})

      :unchanged ->
        :noop
    end

    {:noreply, %{state | connections: new_connections}}
  end

  def handle_info(_, state) do
    {:noreply, state}
  end

  defp via_tuple({_, _} = chain_id) do
    {:via, Registry, {Phylax.Pathfinder.WorkerRegistry, {:chain, chain_id}}}
  end

  defp via_tuple(opts) when is_list(opts) do
    map_id = opts[:map_id]
    root_system_id = opts[:root_system_id]
    via_tuple({map_id, root_system_id})
  end
end
