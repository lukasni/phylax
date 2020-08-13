defmodule Phylax.Zkillboard.Client do
  @moduledoc """
  Zkillboard Websocket client

  See https://github.com/zKillboard/zKillboard/wiki/Websocket for documentation on the Websocket and supported channels
  """

  use WebSockex
  require Logger

  @url "wss://zkillboard.com/websocket/"
  @process_name __MODULE__

  # Client methods

  @spec start_link(any) :: {:error, any} | {:ok, pid}
  def start_link(_) do
    state = %{channels: MapSet.new(["killstream"])}
    WebSockex.start_link(@url, __MODULE__, state, name: @process_name)
  end

  @doc """
  Send a raw text message to the webhook
  """
  def send(message) do
    Logger.debug("Sending text frame with payload: #{message}")
    WebSockex.send_frame(@process_name, {:text, message})
  end

  @doc """
  Subscribe the webhook to a specific channel.
  Received frames will be handled by handle_frame

  Returns `:ok`

  ## Examples

      iex> ExZkb.Client.subscribe("killstream")
      :ok
  """
  def subscribe(channel) when is_binary(channel) do
    Logger.info("Subscribing to channel #{channel}")
    WebSockex.cast(@process_name, {:subscribe, channel})
  end

  def subscribe(%MapSet{} = channels) do
    channels
    |> Enum.map(&subscribe/1)
  end

  @doc """
  Unsubscribe from a previously subscribed channel.

  Returns `:ok`

  ## Examples

      iex> ExZkb.Client.unsubscribe("killstream")
  """
  def unsubscribe(channel) do
    Logger.info("Unsubscribing from channel #{channel}")
    WebSockex.cast(@process_name, {:unsubscribe, channel})
  end

  ## Server callbacks

  def handle_connect(_conn, state) do
    Logger.info("Websocket Connected with state #{inspect(state)}")

    case state[:channels] do
      %MapSet{} = channels -> subscribe(channels)
      nil -> :noop
    end

    {:ok, state}
  end

  def handle_cast({:subscribe, channel}, state) do
    new_state =
      Map.update(state, :channels, MapSet.new([channel]), fn c -> MapSet.put(c, channel) end)

    message = %{"action" => "sub", "channel" => channel}
    frame = {:text, Jason.encode!(message)}
    {:reply, frame, new_state}
  end

  def handle_cast({:unsubscribe, channel}, state) do
    new_state =
      Map.update(state, :channels, MapSet.new([]), fn c -> MapSet.delete(c, channel) end)

    message = %{"action" => "unsub", "channel" => channel}
    frame = {:text, Jason.encode!(message)}
    {:reply, frame, new_state}
  end

  def handle_frame({:text, msg}, state) do
    Task.start(fn -> process_frame(msg) end)

    {:ok, state}
  end

  def handle_frame({type, msg}, state) do
    Logger.info("Received unknown Message - Type: #{inspect(type)} -- Message: #{inspect(msg)}")
    {:ok, state}
  end

  defp process_frame(frame) do
    frame
    |> Jason.decode!()
    |> Phylax.Core.Kill.from_killmail()
    |> Phylax.broadcast()
  end
end
