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

    Nostrum.Api.create_message(channel, embed: embed, content: kill.url)
  end

  def post_watchlist(user_id, added_systems) do
    {:ok, channel} = Nostrum.Api.create_dm(user_id)

    names =
      added_systems
      |> Phylax.EsiHelpers.names()
      |> Enum.map(fn {_id, data} -> data.name end)
      |> Enum.join("`, `")

    message =
      case length(added_systems) do
        1 ->
          "A system you watchlisted has been connected: `#{names}`"

        n ->
          "#{n} systems you watchlisted have been connected: `#{names}`"
      end

    Nostrum.Api.create_message(channel.id, message)
  end
end
