defmodule Phylax.Pathfinder.Map.Worker do
  @moduledoc false

  use GenServer
  require Logger
  alias Phylax.Pathfinder

  @refresh_interval :timer.seconds(30)

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: via_tuple(opts[:map_id]))
  end

  def get_map(map_id) do
    GenServer.call(via_tuple(map_id), :get_map)
  end

  def init(opts) do
    Logger.debug("Starting map worker with options #{inspect(opts)}")
    {:ok, %{map_id: opts[:map_id], graph: nil}, {:continue, :load_map}}
  end

  def handle_continue(:load_map, state) do
    {:noreply, update_map(state)}
  end

  def handle_call(:get_map, _from, state) do
    {:reply, state.graph, state}
  end

  def handle_info(:refresh, state) do
    {:noreply, update_map(state)}
  end

  defp update_map(state) do
    Logger.debug("Updating Map #{state.map_id}")
    old_graph = state.graph
    new_graph = Phylax.Pathfinder.Map.build_map(state.map_id)
    new_state = %{state | graph: new_graph}

    if Pathfinder.Map.changed?(old_graph, new_graph),
      do: Phylax.Pathfinder.broadcast({:map_changed, new_state})

    schedule_refresh()
    new_state
  end

  defp schedule_refresh() do
    Process.send_after(self(), :refresh, @refresh_interval)
  end

  defp via_tuple(map_id) do
    {:via, Registry, {Phylax.Pathfinder.WorkerRegistry, {:map, map_id}}}
  end
end
