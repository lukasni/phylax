defmodule Phylax.Discord.Consumer do
  @moduledoc """
  Consumes events sent by the Discord API
  """

  alias Phylax.Discord.Consumer.{
    MessageCreate,
    Ready
  }

  use Nostrum.Consumer

  def start_link() do
    Consumer.start_link(__MODULE__, max_restarts: 0)
  end

  def handle_event({:READY, msg, _ws_state}) do
    Ready.handle(msg)
  end

  def handle_event({:MESSAGE_CREATE, msg, _ws_state}) do
    MessageCreate.handle(msg)
  end

  def handle_event(_event) do
  end
end
