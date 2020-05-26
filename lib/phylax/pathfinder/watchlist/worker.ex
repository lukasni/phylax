defmodule Phylax.Pathfinder.Watchlist.Worker do
  @moduledoc """
  Worker process for a single user watchlist. Subscribes to "pathfinder"
  broadcasts and sends a discord notification if a watched system is connected

  State:
  ```
  %{
    user_id: user_id_integer,
    chains: %{
      {map_id, root_system_id} => MapSet([system_id])
    }
  }
  ```
  """

  use GenServer

  alias Phylax.Pathfinder, as: PF

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: via_tuple(opts[:user_id]))
  end

  def subscribe(user_id, chain_id, system_id) do
    GenServer.call(via_tuple(user_id), {:subscribe, chain_id, system_id})
  end

  def unsubscribe(user_id, chain_id, system_id) do
    GenServer.call(via_tuple(user_id), {:unsubscribe, chain_id, system_id})
  end

  def stop(user_id) do
    GenServer.stop(via_tuple(user_id))
  end

  def init(opts) do
    PF.subscribe()

    {:ok, %{user_id: opts[:user_id]}, {:continue, :load_watched_systems}}
  end

  def handle_call({:subscribe, chain_id, system_id}, _from, state) do
    chains =
      state.chains
      |> Map.update(chain_id, MapSet.new([system_id]), &MapSet.put(&1, system_id))

    {:reply, :ok, %{state | chains: chains}}
  end

  def handle_call({:unsubscribe, chain_id, system_id}, _from, state) do
    chains =
      state.chains
      |> Map.update(chain_id, MapSet.new([]), &MapSet.delete(&1, system_id))

    {:reply, :ok, %{state | chains: chains}}
  end

  def handle_continue(:load_watched_systems, state) do
    chains =
      state.user_id
      |> PF.list_watched_systems()
      |> PF.Watchlist.group_chains()
      |> Enum.map(fn {key, watches} ->
        {key, watches |> Enum.map(& &1.system_id) |> MapSet.new()}
      end)
      |> Map.new()

    new_state =
      state
      |> Map.put(:chains, chains)

    {:noreply, new_state}
  end

  def handle_info(
        {:chain_update, %{chain_id: chain_id, added: added_systems}},
        %{chains: chains} = state
      )
      when is_map_key(chains, chain_id) do
    case MapSet.intersection(added_systems, state.chains[chain_id]) |> MapSet.to_list() do
      [] ->
        :noop

      list ->
        Phylax.Discord.post_watchlist(state.user_id, list)
    end

    {:noreply, state}
  end

  def handle_info(_, state) do
    {:noreply, state}
  end

  defp via_tuple(user_id) do
    {:via, Registry, {Phylax.Pathfinder.WorkerRegistry, {:watchlist, user_id}}}
  end
end
