defmodule Phylax.Discord.Commands.Pathfinder.Unsubscribe do
  @moduledoc """
  `pf map` command definition
  """

  @behaviour Nosedrum.Command

  alias Nosedrum.Predicates
  alias Nosedrum.Helpers
  alias Nostrum.Api
  alias Phylax.Discord.Util
  alias Phylax.Pathfinder, as: PF

  @impl true
  def usage, do: ["pf unsubscribe [map_name:string] [root_system:string]"]

  @impl true
  def description() do
    """
    Unsubscribe from a watched map. Will stop tracking kills in that map in this channel.

    Use `--all` in place of a name to stop tracking all maps.
    """
  end

  @impl true
  def predicates, do: [&Predicates.guild_only/1, Predicates.has_permission(:manage_roles)]

  @impl true
  def command(msg, [map_name, root_system]) do
    response =
      case PF.delete_watched_chain(msg.channel_id, map_name, root_system) do
        {:ok, _} ->
          "Stopped tracking map #{Helpers.escape_server_mentions(map_name)} with root system #{
            Helpers.escape_server_mentions(root_system)
          } in this channel."

        {:error, :system_not_found} ->
          "No system named #{Helpers.escape_server_mentions(root_system)} found. Make sure to use the EVE name, not the pathfinder alias."

        {:error, :map_not_found} ->
          "No map named #{Helpers.escape_server_mentions(map_name)} found."
      end

    Api.create_message(msg.channel_id, response)
  end

  def command(msg, _arg) do
    response = Util.usage(__MODULE__)

    Api.create_message(msg.channel_id, response)
  end
end
