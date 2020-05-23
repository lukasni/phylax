defmodule Phylax.Discord.Commands.Pathfinder.Subscribe do
  @moduledoc """
  `pf subscribe` command definition

  .pathfinder subscribe --map "Home Chain" --root J140750 --exclude "Wardec Mechanics" --exclude "No Vacancies."
  """

  @behaviour Nosedrum.Command

  require Logger

  alias Nosedrum.Predicates
  alias Nosedrum.Helpers
  alias Nostrum.Api
  alias Phylax.Discord.Util
  alias Phylax.Pathfinder, as: PF

  @impl true
  def usage, do: ["pathfinder subscribe <options...>"]

  @impl true
  def description() do
    """
    Pathfinder chain kill tracking. Will track all kills in a pathfinder chain (systems connected to specified root).

    This command supports the following options:

    ```
    -m, --map <name:string> (required)
        name of the Pathfinder Map the chain is on, e.g. "Home Chain".

    -r, --root <name:string> (required)
        Name of the root system for the chain, e.g. "J140750".
        Use the EVE name, not the pathfinder alias.

    -X, --exclude <name:string> (optional)
        Name of entity (character, corp, alliance) whose kills should be ignored.
        This option can be specified multiple times.
    ```
    """
  end

  @impl true
  def predicates, do: [&Predicates.guild_only/1, Predicates.has_permission(:manage_roles)]

  @impl true
  def parse_args(args) do
    OptionParser.parse(
      args,
      strict: [
        # --map | -m
        #   name of the Pathfinder Map the chain is on, e.g. "Home Chain"
        map: :string,
        # --root | -r
        #   EVE Name of the root system for the chain, e.g. "J140750"
        root: :string,
        # --exclude | -X
        #   Name of entity whose kills should be ignored, can be specified multiple times.
        exclude: [:string, :keep]
      ],
      aliases: [X: :exclude, m: :map, r: :root]
    )
  end

  @impl true
  def command(msg, {options, [], []}) when options != [] do

    response =
      with {:args, true} <- {:args, Util.has_required_args?(options, [:map, :root])},
           {:ok, _} <- PF.add_watched_chain(msg.channel_id, options) do
        "Now tracking map #{Helpers.escape_server_mentions(options[:map])} with root system #{
          Helpers.escape_server_mentions(options[:root])
        } in this channel."
      else
        {:args, false} ->
          "Missing required arguments. Check `help pf subscribe`"

        {:error, :system_not_found} ->
          "No system named #{Helpers.escape_server_mentions(options[:root])} found. Make sure to use the EVE name, not the pathfinder alias."

        {:error, :map_not_found} ->
          "No map named #{Helpers.escape_server_mentions(options[:map])} found."

        error ->
          Logger.warn("#{__MODULE__}: #{inspect error}")
          """
          Unexpected error encountered, please try again.

          #{Util.usage(__MODULE__)}
          """
      end

    Api.create_message(msg.channel_id, response)
  end

  def command(msg, _opts) do
    response = Util.usage(__MODULE__)

    Api.create_message(msg.channel_id, response)
  end
end
