defmodule Phylax.Killbot.Worker do
  @moduledoc """
  Worker Process for the Killbot function.
  One of these processes is launched for every discord channel that has a killbot subscription.

  The subscribed alliances and corporations are stored in state as a MapSet.

  The worker subscribes the the `:killboard` channel on PubSub. Every kill broadcast to that channel
  is received. If the victim or any of the attackers are affiliated (a member of) any of the watched
  entities, the kill is posted to the subscribing channel as a loss or kill respectively.
  This is done in an unlinked Task to guard against errors in the ESI requests needed to flesh out
  the killbot message.
  """
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

  def whereis(channel_id) do
    GenServer.whereis(via_tuple(channel_id))
  end

  # Server Callbacks

  def init(opts) do
    Logger.debug("Starting killbot worker with options #{inspect(opts)}")
    # Subscribe the server process to the `:killboard` PubSub channel
    Phylax.subscribe(:killboard)
    # set the initial state. Loading of the entities from the DB is
    # deferred to a handle_continue to speed up server boot time.
    {:ok, %{channel: opts[:channel], entities: MapSet.new()}, {:continue, :load_entities}}
  end

  def handle_continue(:load_entities, state) do
    # Load the subscribed entities from the database and add them to the server state
    entities =
      Phylax.Killbot.list_entities(state.channel)
      |> Enum.map(& &1.entity_id)
      |> MapSet.new()

    Logger.debug("Adding entities #{inspect(entities)} for channel #{state.channel}")

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
    # Handle new kills received from the kill provider
    cond do
      # Kill: Any of the attackers are affiliated with any of the watched entities
      MapSet.disjoint?(state.entities, kill.affiliated.killers) == false ->
        Task.start(fn -> Phylax.Discord.post_kill(state.channel, kill, :kill) end)

      # Loss: The victim is affiliated with any of the watched entities
      MapSet.disjoint?(state.entities, kill.affiliated.victim) == false ->
        Task.start(fn -> Phylax.Discord.post_kill(state.channel, kill, :loss) end)

      true ->
        :noop
    end

    {:noreply, state}
  end

  defp via_tuple(channel_id) do
    {:via, Registry, {Phylax.Killbot.WorkerRegistry, channel_id}}
  end
end
