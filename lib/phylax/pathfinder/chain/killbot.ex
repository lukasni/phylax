defmodule Phylax.Pathfinder.Chain.Killbot do
  @moduledoc false

  use GenServer

  require Logger

  alias Phylax.Pathfinder, as: PF

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: via_tuple(opts[:channel]))
  end

  def subscribe(channel_id, chain_id, excludes) do
    GenServer.call(via_tuple(channel_id), {:subscribe, chain_id, excludes})
  end

  def unsubscribe(channel_id, chain_id) do
    GenServer.call(via_tuple(channel_id), {:unsubscribe, chain_id})
  end

  def stop(channel_id) do
    GenServer.stop(via_tuple(channel_id))
  end

  def init(opts) do
    Logger.debug("Starting chain killbot worker with options #{inspect(opts)}")
    Phylax.subscribe(:killboard)

    {:ok, %{channel: opts[:channel], chains: %{}}, {:continue, :load_chains}}
  end

  def handle_continue(:load_chains, state) do
    chains =
      state.channel
      |> PF.get_watched_chains()
      |> group_chains()

    {:noreply, %{state | chains: chains}}
  end

  def handle_info({:kill, kill}, state) do
    valid_chains =
      for {chain, excludes} <- state.chains,
          PF.kill_in_chain?(kill, chain),
          not PF.excluded?(kill, excludes) do
        Logger.debug("Kill in chain #{inspect(chain)}, #{kill.url}")

        chain
      end

    case valid_chains do
      [] ->
        {:noreply, state}

      chains ->
        Phylax.Discord.post_chain_kill(kill, chains, state.channel)
        {:noreply, Map.update(state, :total_kills, 1, & &1+1)}
    end
  end

  def handle_info(_, state) do
    {:noreply, state}
  end

  defp group_chains(chains) do
    chains
    |> Enum.map(fn c ->
      {{c.map_id, c.root_system_id}, MapSet.new(Enum.map(c.excluded_entities, & &1.entity_id))}
    end)
    |> Map.new()
  end

  defp via_tuple(channel_id) do
    {:via, Registry, {Phylax.Pathfinder.WorkerRegistry, {:killbot, channel_id}}}
  end
end
