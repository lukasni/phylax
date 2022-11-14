defmodule Phylax.Discord.Consumer.MessageCreate do
  @moduledoc """
  Handles the `MESSAGE_CREATE` event.
  """

  @nosedrum_storage Nosedrum.Storage.ETS

  alias Nosedrum.Invoker.Split, as: CommandInvoker
  alias Nostrum.Api

  def handle(msg) do
    msg = Phylax.Discord.Util.replace_fancy_quotes(msg)

    unless msg.author.bot do
      case CommandInvoker.handle_message(msg, @nosedrum_storage) do
        {:error, {:unknown_subcommand, _name, :known, known}} ->
          Api.create_message(
            msg.channel_id,
            "🚫 unknown subcommand, known subcommands: `#{Enum.join(known, "`, `")}`"
          )

        {:error, :predicate, {:error, reason}} ->
          Api.create_message(msg.channel_id, "❌ cannot evaluate permissions: #{reason}")

        {:error, :predicate, {:noperm, reason}} ->
          Api.create_message(msg.channel_id, reason)

        _ ->
          :ok
      end
    end
  end
end
