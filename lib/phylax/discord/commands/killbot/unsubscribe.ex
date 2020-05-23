defmodule Phylax.Discord.Commands.Killbot.Unsubscribe do
  @moduledoc """
  `pf map` command definition
  """

  @behaviour Nosedrum.Command

  alias Nosedrum.Predicates
  alias Nosedrum.Helpers
  alias Nostrum.Api
  alias Phylax.Discord.Util
  alias Phylax.Killbot, as: KB
  alias Phylax.Killbot.Entry

  @impl true
  def usage, do: ["killboard unsubscribe <name:string>"]

  @impl true
  def description() do
    """
    Unsubscribe from entity in this channel.
    """
  end

  @impl true
  def predicates, do: [&Predicates.guild_only/1, Predicates.has_permission(:manage_roles)]

  @impl true
  def command(msg, [name]) do
    response =
      with %Entry{} = entry <- KB.get_entry(msg.channel_id, name),
           :ok <- KB.unsubscribe(entry) do
        "**#{Helpers.escape_server_mentions(name)}** deleted from this channel"
      else
        nil ->
          "**#{Helpers.escape_server_mentions(name)}** is not being watched in this channel"
      end

    Api.create_message(msg.channel_id, response)
  end

  def command(msg, _arg) do
    response = Util.usage(__MODULE__)

    Api.create_message(msg.channel_id, response)
  end
end
