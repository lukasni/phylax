defmodule Phylax.Pathfinder.Watchlist do
  @moduledoc false

  require Logger

  def group_chains(watches) do
    watches
    |> Enum.group_by(& &1.guild_id)
    |> Enum.reduce(%{}, fn {guild_id, watches}, acc ->
      case Phylax.Pathfinder.Config.get_default_chain(guild_id) do
        nil ->
          Logger.info("Watchlist entry in guild without configured root system: #{guild_id}")
          acc

        chain ->
          Map.put(acc, chain, watches)
      end
    end)
  end
end
