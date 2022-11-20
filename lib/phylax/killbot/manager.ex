defmodule Phylax.Killbot.Manager do
  @moduledoc """
  Manager server for the Killbot function.
  Responsible for starting and stopping `Phylax.Killbot.Worker` processes.any()

  At boot time, this server starts a killbot worker for each channel with one or more Killbot subscriptions

  This server is also responsible for adding additional workers if a new subscription is added
  and for removing workers if the last subscription in the channel is removed.
  """

  use GenServer
  require Logger

  @name __MODULE__

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: @name)
  end

  def subscribe(channel_id, entity_id) do
    GenServer.call(@name, {:subscribe, channel_id, entity_id})
  end

  def unsubscribe(channel_id, entity_id) do
    GenServer.call(@name, {:unsubscribe, channel_id, entity_id})
  end

  def unsubscribe_all(channel_id) do
    GenServer.call(@name, {:unsubscribe_all, channel_id})
  end

  # Server Callbacks

  def init(initial_state) do
    {:ok, initial_state, {:continue, :load_workers}}
  end

  def handle_continue(:load_workers, _state) do
    # Load channels with one or more subscribed entities
    channels = Phylax.Killbot.channels()

    # Start a single worker for each channel
    for channel <- channels do
      Phylax.Killbot.WorkerSupervisor.start_child(channel: channel)
    end

    {:noreply, %{channels: MapSet.new(channels)}}
  end

  def handle_call({:subscribe, channel_id, entity_id}, _from, state) do
    new_channels =
      case Phylax.Killbot.Worker.whereis(channel_id) do
        # No Worker process exists for this channel, start one and ID to manager state
        nil ->
          Phylax.Killbot.WorkerSupervisor.start_child(channel: channel_id)
          MapSet.put(state.channels, channel_id)

        _ ->
          state.channels
      end

    # Subscribe the new worker to the added entity.
    # This may be redundant since the worker process already reads the new entity from the DB.
    Phylax.Killbot.Worker.subscribe(channel_id, entity_id)

    {:reply, :ok, Map.put(state, :channels, new_channels)}
  end

  def handle_call({:unsubscribe, channel_id, entity_id}, _from, state) do
    channels =
      case Phylax.Killbot.Worker.unsubscribe(channel_id, entity_id) do
        # No watched entities left in this channel
        [] ->
          # Stop the worker process and remove the channel id from the manager state
          Phylax.Killbot.Worker.stop(channel_id)
          MapSet.delete(state.channels, channel_id)

        _ ->
          state.channels
      end

    {:reply, :ok, Map.put(state, :channels, channels)}
  end

  def handle_call({:unsubscribe_all, channel_id}, _from, state) do
    # Stop the worker process if it exists
    if Phylax.Killbot.Worker.whereis(channel_id) do
      Phylax.Killbot.Worker.stop(channel_id)
    end

    # Remove worker id from manager state
    {:reply, :ok, Map.update!(state, :channels, &MapSet.delete(&1, channel_id))}
  end
end
