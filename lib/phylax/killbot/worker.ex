defmodule Phylax.Killbot.Worker do
  use GenServer

  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: via_tuple(opts[:channel]))
  end

  def subscribe(channel_id, entity_id) do
    GenServer.call(via_tuple(channel_id), {:subscribe, entity_id})
  end

  def unsubscribe(channel_id, entity_id) do
    GenServer.call(via_tuple(channel_id), {:unsubscribe, entity_id})
  end

  def stop(channel_id) do
    GenServer.stop(via_tuple(channel_id))
  end

  # Server Callbacks

  def init(opts) do
    Logger.debug("Starting killbot worker with options #{inspect opts}")
    Phylax.subscribe(:killboard)
    {:ok, %{channel: opts[:channel], entities: MapSet.new()}, {:continue, :load_entities}}
  end

  def handle_continue(:load_entities, state) do
    entities =
      Phylax.Killbot.list_entities(state.channel)
      |> Enum.map(& &1.entity_id)
      |> MapSet.new()

    Logger.debug("Adding entities #{inspect entities} for channel #{state.channel}")

    {:noreply, %{state | entities: entities}}
  end

  def handle_call({:subscribe, entity_id}, _from, state) do
    new_entities = MapSet.put(state.entities, entity_id)

    {:reply, MapSet.to_list(new_entities), %{state | entities: new_entities}}
  end

  def handle_call({:unsubscribe, entity_id}, _from, state) do
    new_entities = MapSet.delete(state.entities, entity_id)
    {:reply, MapSet.to_list(new_entities), %{state | entities: new_entities}}
  end

  def handle_info({:kill, kill}, state) do
    cond do
      MapSet.disjoint?(state.entities, kill.affiliated.killers) == false ->
        Task.start(fn -> post_kill(state.channel, kill, :kill) end)

      MapSet.disjoint?(state.entities, kill.affiliated.victim) == false ->
        Task.start(fn -> post_kill(state.channel, kill, :loss) end)

      true ->
        :noop
    end

    {:noreply, state}
  end

  defp post_kill(channel, kill, type) do
    embed =
      kill
      |> Phylax.Killbot.DiscordEmbed.build(
        location: Phylax.EsiHelpers.location(kill),
        names: Phylax.EsiHelpers.names(kill),
        type: type
      )

    Nostrum.Api.create_message(channel, embed: embed)
  end

  defp via_tuple(channel_id) do
    {:via, Registry, {Phylax.Killbot.WorkerRegistry, channel_id}}
  end
end
