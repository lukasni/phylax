defmodule Phylax.Discord.Consumer.MessageCreate do
  @moduledoc """
  Handles the `MESSAGE_CREATE` event.
  """

  @nosedrum_storage Nosedrum.Storage.ETS

  alias Nosedrum.Invoker.Split, as: CommandInvoker

  def handle(msg) do
    unless msg.author.bot do
      CommandInvoker.handle_message(msg, @nosedrum_storage)
    end
  end
end
