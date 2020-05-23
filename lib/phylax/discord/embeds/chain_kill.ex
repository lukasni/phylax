defmodule Phylax.Discord.Embeds.ChainKill do
  @moduledoc false

  alias Phylax.Core.Kill
  alias Phylax.Discord.Embeds.Kill, as: KillEmbed
  import Nostrum.Struct.Embed

  def build(%Kill{} = kill, opts) do
    embed = KillEmbed.build(kill, opts)
    jumps = Phylax.Pathfinder.Chain.route(opts[:chains] |> hd(), kill.system_id)
    route = jumps |> Enum.join(" 🠪 ")

    embed
    |> put_description(route)
    |> put_title(format_title(jumps))
  end

  def format_title([system]) do
    "Activity in #{system}. Maybe go check that?"
  end

  def format_title([_ | [_]]) do
    "Activity 1 jump down chain"
  end

  def format_title(jumps) do
    "Activity #{length(jumps) - 1} jumps down chain"
  end
end
