defmodule Phylax.Pathfinder.Manager do
  @moduledoc """
  Management server for pathfinder maps, chains and the workers that use them

  State
  ```elixir
  %{
    maps:
      map_id_integer => %{
        root_system_id_integer => %{
          killbots: [channel_ids]
          watchers: [channel_ids]
        }
      }
    workers: %{
      killbots: %{
        channel_id: count
      }
      watchers: %{
        channel_id: count
      }
    }
  }
  ```
  """

  use GenServer
  require Logger
  alias Phylax.Pathfinder, as: PF

  @name __MODULE__

  @new_chain_state %{killbots: MapSet.new(), watchers: MapSet.new()}

  @initial_state %{maps: %{}, workers: %{killbots: %{}, watchers: %{}}}

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: @name)
  end

  # Server Callbacks

  def init(_) do
    {:ok, @initial_state, {:continue, :load_workers}}
  end

  def handle_continue(:load_workers, state) do
    state =
      state
      |> start_chain_killbots(PF.get_watched_chains())

    Phylax.Pathfinder.subscribe()

    {:noreply, state}
  end

  def handle_info({:chain_added, chain}, state) do
    {:noreply, start_chain_killbot(chain, state)}
  end

  def handle_info({:chain_deleted, chain}, state) do
    state =
      state
      |> remove_killbot(chain)
      |> maybe_unwatch_chain(chain)
      |> maybe_unwatch_map(chain)

    {:noreply, state}
  end

  def handle_info(_, state) do
    {:noreply, state}
  end

  defp start_chain_killbots(state, chains) do
    Enum.reduce(chains, state, &start_chain_killbot/2)
  end

  defp start_chain_killbot(watched_chain, state) do
    state
    |> watch_map(watched_chain)
    |> watch_chain(watched_chain)
    |> add_killbot(watched_chain)
  end

  defp watch_map(state, %{map_id: map_id}) do
    if Map.has_key?(state.maps, map_id) do
      state
    else
      PF.Map.Worker.start_tracking_map(map_id)
      put_in(state, [:maps, map_id], %{})
    end
  end

  defp watch_chain(state, %{map_id: map_id, root_system_id: root_system_id}) do
    if Map.has_key?(state[:maps][map_id], root_system_id) do
      state
    else
      PF.Chain.Worker.start_tracking_chain({map_id, root_system_id})
      put_in(state, [:maps, map_id, root_system_id], @new_chain_state)
    end
  end

  defp add_killbot(state, chain) do
    if chain.channel_id not in Map.keys(state.workers.killbots) do
      PF.Chain.KillbotSupervisor.start_child(channel: chain.channel_id)
    else
      PF.Chain.Killbot.subscribe(chain)
    end

    state
    |> update_in([:workers, :killbots, chain.channel_id], &(&1 || 0) + 1)
    |> update_in([:maps, chain.map_id, chain.root_system_id, :killbots], &MapSet.put(&1, chain.channel_id))
  end

  defp remove_killbot(state, chain) do
    if get_in(state, [:workers, :killbots, chain.channel_id]) == 1 do
      Logger.info("Stoping worker #{chain.channel_id}")
      PF.Chain.Killbot.stop(chain.channel_id)

      state
      |> delete_in([:workers, :killbots, chain.channel_id])
    else
      Logger.info("Decrementing worker #{chain.channel_id}")
      PF.Chain.Killbot.unsubscribe(chain.channel_id, {chain.map_id, chain.root_system_id})

      state
      |> update_in([:workers, :killbots, chain.channel_id], & &1-1)
    end
    |> update_in([:maps, chain.map_id, chain.root_system_id, :killbots], &MapSet.delete(&1, chain.channel_id))
  end

  defp maybe_unwatch_chain(state, chain) do
    if MapSet.size(get_in(state, [:maps, chain.map_id, chain.root_system_id, :killbots])) == 0 do
      PF.Chain.Worker.stop_tracking_chain({chain.map_id, chain.root_system_id})

      state
      |> delete_in([:maps, chain.map_id, chain.root_system_id])
    else
      state
    end
  end

  defp maybe_unwatch_map(state, chain) do
    if map_size(get_in(state, [:maps, chain.map_id])) == 0 do
      PF.Map.Worker.stop_tracking_map(chain.map_id)

      state
      |> delete_in([:maps, chain.map_id])
    else
      state
    end
  end

  defp delete_in(data, keys) do
    data
    |> pop_in(keys)
    |> elem(1)
  end
end
