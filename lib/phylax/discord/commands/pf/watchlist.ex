defmodule Phylax.Discord.Commands.Pathfinder.Watchlist do
  @moduledoc """
  `pf map` command definition
  """

  @behaviour Nosedrum.Command

  @prefix Application.fetch_env!(:nosedrum, :prefix)

  alias Nostrum.Api
  alias Nosedrum.Helpers
  alias Nosedrum.Predicates

  require Logger

  @impl true
  def usage,
    do: ["pf watchlist add [name:string]", "pf watchlist remove [name:string]", "pf watchlist"]

  @impl true
  def description() do
    """
    Pathfinder Watchlist. If a watched system is added to pathfinder, you will be notified via direct message.

    Calling without an argument will show your currently watchlisted systems.
    """
  end

  @impl true
  def predicates, do: [&Predicates.guild_only/1]

  @impl true
  def command(msg, ["add" | [name]]) do
    # TODO: Error handling
    response =
      case Phylax.Pathfinder.add_watched_system(msg.author.id, msg.guild_id, name) do
        {:ok, _} ->
          "You are now watching `#{Helpers.escape_server_mentions(name)}`. You will be notified if the system is connected."

        e ->
          format_error(e)
      end

    Api.create_message(msg.channel_id, response)
  end

  def command(msg, ["remove" | [name]]) do
    # TODO: Implementation
    response =
      case Phylax.Pathfinder.delete_watched_system(msg.author.id, msg.guild_id, name) do
        {:ok, 0} ->
          "You weren't watching `#{Helpers.escape_server_mentions(name)}`. No action performed."

        {:ok, _count} ->
          "You are no longer watching `#{Helpers.escape_server_mentions(name)}`."

        e ->
          format_error(e)
      end

    Api.create_message(msg.channel_id, response)
  end

  def command(msg, []) do
    response =
      case Phylax.Pathfinder.list_watched_systems(msg.author.id, msg.guild_id) do
        [] ->
          "You currently aren't watching any systems"

        list ->
          """
          You will be notified if any of the following systems are connected to the default chain:
          *#{format_systems(list)}*
          """
      end

    Api.create_message(msg.channel_id, response)
  end

  def command(msg, _arg) do
    response = """
    ℹ️ usage:
    ```ini
    #{
      usage()
      |> Stream.map(&"#{@prefix}#{&1}")
      |> Enum.join("\n")
    }
    ```
    """

    Api.create_message(msg.channel_id, response)
  end

  defp format_systems(list) do
    list
    |> Enum.map(& &1.system_id)
    |> Phylax.EsiHelpers.names()
    |> Enum.map(fn {_, info} -> info.name end)
    |> Enum.join(", ")
  end

  defp format_error({:error, :too_short}),
    do: "Search term too short. Has to be a minimum of 3 characters."

  defp format_error({:error, :ambiguous}),
    do: "Ambiguous search result. Use the full EVE name of the system."

  defp format_error({:error, :not_found}), do: "System not found."

  defp format_error(error) do
    Logger.warn("#{__MODULE__} - UNEXPECTED ERROR: #{inspect(error)}")
    "Unexpected error encountered."
  end
end
