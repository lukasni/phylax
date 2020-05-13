defmodule Phylax.Discord.Commands.Ping do
  @moduledoc """
  `ping` command definition
  """

  @behaviour Nosedrum.Command

  alias Nosedrum.Helpers
  alias Nostrum.Api

  @impl true
  def usage, do: ["ping [echo:str]"]

  @impl true
  def description() do
    """
    Ping command to check bot presence.
    Returns the first argument or "Pong!" when called with no arguments.
    """
  end

  @impl true
  def predicates, do: []

  @impl true
  def command(msg, []) do
    response = "Pong!"
    Api.create_message(msg.channel_id, response)
  end

  def command(msg, arg) do
    response = Enum.join(arg, " ") |> Helpers.escape_server_mentions()
    Api.create_message(msg.channel_id, response)
  end
end
