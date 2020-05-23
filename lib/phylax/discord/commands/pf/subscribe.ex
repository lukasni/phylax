defmodule Phylax.Discord.Commands.Pathfinder.Subscribe do
  @moduledoc """
  `pf map` command definition

  .pathfinder subscribe --map "Home Chain" --root J140750 --exclude-alliance "Wardec Mechanics" --exclude-alliance "No Vacancies."
  """

  @behaviour Nosedrum.Command

  alias Nosedrum.Predicates
  alias Nosedrum.Helpers
  alias Nostrum.Api
  alias Phylax.Discord.Util
  alias Phylax.Pathfinder, as: PF

  @impl true
  def usage, do: ["pf subscribe [map_name:string] [root_system:string]"]

  @impl true
  def description() do
    """
    Pathfinder map selection. Will track third-party kills in `map` connected to the `root_system` (system name, not alias) in this channel.
    Only kills that aren't already reported in a killbot channel will be reported. I.e, only out-of-corp kills.

    Maps are internally represented by the map id, so changing the map name won't stop tracking.
    If the map is recreated, it needs to be set to track again using this command, as the internal ID changes.
    """
  end

  @impl true
  def predicates, do: [&Predicates.guild_only/1, Predicates.has_permission(:manage_roles)]

  @impl true
  def command(msg, opts) do
    {options, _invalid, _rest} =
      opts
      |> OptionParser.parse(
        strict: [map: :string, root: :string, exclude: :keep],
        aliases: [X: :exclude, m: :map, r: :root]
      )

    response =
      case PF.add_watched_chain(msg.channel_id, options) do
        {:ok, _} ->
          "Now tracking map #{Helpers.escape_server_mentions(options[:map])} with root system #{
            Helpers.escape_server_mentions(options[:root])
          } in this channel."

        {:error, :system_not_found} ->
          "No system named #{Helpers.escape_server_mentions(options[:root])} found. Make sure to use the EVE name, not the pathfinder alias."

        {:error, :map_not_found} ->
          "No map named #{Helpers.escape_server_mentions(options[:map])} found."

        _ ->
          """
          Unexpected error encountered, please try again.

          #{Util.usage(__MODULE__)}
          """
      end

    Api.create_message(msg.channel_id, response)
  end

  def command(msg, _arg) do
    response = Util.usage(__MODULE__)

    Api.create_message(msg.channel_id, response)
  end
end
