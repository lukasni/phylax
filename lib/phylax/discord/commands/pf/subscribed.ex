defmodule Phylax.Discord.Commands.Pathfinder.Subscribed do
  @moduledoc """
  `pf map` command definition
  """

  @behaviour Nosedrum.Command

  alias Nosedrum.Predicates
  alias Nostrum.Api
  alias Phylax.Discord.Util
  alias Phylax.Pathfinder, as: PF

  @impl true
  def usage, do: ["pf subscribed"]

  @impl true
  def description() do
    """
    Show chains currently tracked in this channel.
    """
  end

  @impl true
  def predicates, do: [&Predicates.guild_only/1, Predicates.has_permission(:manage_roles)]

  @impl true
  def command(msg, []) do
    response =
      case PF.get_watched_chains(msg.channel_id) do
        [] -> "No watched chains in this channel"
        chains -> format_chains(chains)
      end

    Api.create_message(msg.channel_id, response)
  end

  def command(msg, _arg) do
    response = Util.usage(__MODULE__)

    Api.create_message(msg.channel_id, response)
  end

  defp format_chains(chains) do
    """
    Currently tracking:

    #{Enum.map(chains, &Task.async(fn -> format_chain(&1) end)) |> Enum.map(&Task.await/1) |> Enum.join("")}
    """
  end

  defp format_chain(chain) do
    map_name = PF.Map.get_map_name(chain.map_id)
    {:ok, system, _} = ExEsi.API.Universe.systems(chain.root_system_id) |> ExEsi.request()

    """
    Map *#{map_name}* with root system *#{system["name"]}*
        #{if chain.excluded_entities != [] do
      "Exclude: " <> (chain.excluded_entities |> Enum.map(& &1.entity_name) |> Enum.join(", "))
    end}
    """
  end
end
