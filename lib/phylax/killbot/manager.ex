defmodule Phylax.Killbot.Manager do
  @moduledoc false

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
    channels = Phylax.Killbot.channels()

    for channel <- channels do
      Logger.debug("Starting worker for channel #{channel}")
      Phylax.Killbot.WorkerSupervisor.start_child(channel: channel)
    end

    {:noreply, %{channels: MapSet.new(channels)}}
  end

  def handle_call({:subscribe, channel_id, entity_id}, _from, state) do
    new_channels =
      case channel_id in state.channels do
        true ->
          state.channels

        false ->
          Phylax.Killbot.WorkerSupervisor.start_child(channel: channel_id)
          MapSet.put(state.channels, channel_id)
      end

    Phylax.Killbot.Worker.subscribe(channel_id, entity_id)

    {:reply, :ok, Map.put(state, :channels, new_channels)}
  end

  def handle_call({:unsubscribe, channel_id, entity_id}, _from, state) do
    channels =
      case Phylax.Killbot.Worker.unsubscribe(channel_id, entity_id) do
        [] ->
          Phylax.Killbot.Worker.stop(channel_id)
          MapSet.delete(state.channels, channel_id)

        _ ->
          state.channels
      end

    {:reply, :ok, Map.put(state, :channels, channels)}
  end

  def handle_call({:unsubscribe_all, channel_id}, _from, state) do
    channels =
      case channel_id in state.channels do
        true ->
          Phylax.Killbot.Worker.stop(channel_id)
          MapSet.delete(state.channels, channel_id)

        false ->
          state.channels
      end

    {:reply, :ok, Map.put(state, :channels, channels)}
  end
end
