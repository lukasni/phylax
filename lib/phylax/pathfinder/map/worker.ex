defmodule Phylax.Pathfinder.Map.Worker do
  @moduledoc """
  Pathfinder Map Server. Single process for all maps.

  Maintains the graphs for all active connections per tracked map.

  State:
  ```elixir
  %{
    integer_map_id => %Graph{}
  }
  """

  use GenServer
  require Logger
  alias Phylax.Pathfinder

  @name __MODULE__
  @refresh_interval :timer.seconds(30)

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: @name)
  end

  def get_map(map_id) do
    GenServer.call(@name, {:get_map, map_id})
  end

  def start_tracking_map(map_id) do
    GenServer.call(@name, {:add_map, map_id})
  end

  def stop_tracking_map(map_id) do
    GenServer.call(@name, {:remove_map, map_id})
  end

  def init(opts) do
    schedule_refresh()
    Logger.debug("Starting map worker with options #{inspect(opts)}")
    {:ok, %{}}
  end

  def handle_call({:get_map, map_id}, _from, state) do
    {:reply, state[map_id], state}
  end

  def handle_call({:add_map, map_id}, _from, state) do
    new_state = update_map(state, map_id)
    {:reply, new_state[map_id], new_state}
  end

  def handle_call({:remove_map, map_id}, _from, state) do
    {:reply, :ok, Map.delete(state, map_id)}
  end

  def handle_info(:refresh, state) do
    schedule_refresh()
    {:noreply, update_maps(state)}
  end

  defp update_maps(state) do
    state
    |> Map.keys()
    |> Enum.reduce(state, fn map, state ->
      update_map(state, map)
    end)
  end

  defp update_map(state, map_id) do
    Logger.debug("Updating Map #{map_id}")
    old_graph = state[map_id]
    new_graph = Phylax.Pathfinder.Map.build_map(map_id)
    new_state = Map.put(state, map_id, new_graph)

    if Pathfinder.Map.changed?(old_graph, new_graph),
      do: Phylax.Pathfinder.broadcast({:map_changed, %{map_id: map_id, graph: new_graph}})

    new_state
  end

  defp schedule_refresh() do
    Process.send_after(self(), :refresh, @refresh_interval)
  end
end
