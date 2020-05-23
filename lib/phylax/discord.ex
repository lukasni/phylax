defmodule Phylax.Discord do
  @moduledoc false

  def post_chain_kill(kill, chains, channel) do
    embed =
      kill
      |> Phylax.Discord.Embeds.ChainKill.build(
        location: Phylax.EsiHelpers.location(kill),
        names: Phylax.EsiHelpers.names(kill),
        type: :neutral,
        chains: chains
      )

    Nostrum.Api.create_message(channel, embed: embed)
  end

  def post_kill(channel, kill, type) do
    embed =
      kill
      |> Phylax.Discord.Embeds.Kill.build(
        location: Phylax.EsiHelpers.location(kill),
        names: Phylax.EsiHelpers.names(kill),
        type: type
      )

    Nostrum.Api.create_message(channel, embed: embed)
  end
end
