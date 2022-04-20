defmodule Phylax.Discord.Consumer.Ready do
  alias Nosedrum.Storage.ETS, as: CommandStorage
  alias Nostrum.Api
  alias Phylax.Discord.Commands

  @commands %{
    ["help"] => Commands.Help,
    ["ping"] => Commands.Ping,
    ["pathfinder", "subscribe"] => Commands.Pathfinder.Subscribe,
    ["pf", "subscribe"] => Commands.Pathfinder.Subscribe,
    ["pathfinder", "subscribed"] => Commands.Pathfinder.Subscribed,
    ["pf", "subscribed"] => Commands.Pathfinder.Subscribed,
    ["pathfinder", "unsubscribe"] => Commands.Pathfinder.Unsubscribe,
    ["pf", "unsubscribe"] => Commands.Pathfinder.Unsubscribe,
    ["pathfinder", "watchlist"] => Commands.Pathfinder.Watchlist,
    ["pf", "watchlist"] => Commands.Pathfinder.Watchlist,
    ["pathfinder", "config"] => Commands.Pathfinder.Config,
    ["pf", "config"] => Commands.Pathfinder.Config,
    ["kb", "subscribe"] => Commands.Killbot.Subscribe,
    ["killboard", "subscribe"] => Commands.Killbot.Subscribe,
    ["kb", "subscribed"] => Commands.Killbot.Subscribed,
    ["killboard", "subscribed"] => Commands.Killbot.Subscribed,
    ["kb", "unsubscribe"] => Commands.Killbot.Unsubscribe,
    ["killboard", "unsubscribe"] => Commands.Killbot.Unsubscribe
  }

  @bot_prefix Application.fetch_env!(:nosedrum, :prefix)

  def handle(_data) do
    :ok = load_commands()
    :ok = Api.update_status(:online, "you | #{@bot_prefix}help", 2)
  end

  defp load_commands() do
    @commands
    |> Enum.each(fn {name, command} -> CommandStorage.add_command(name, command) end)
  end
end
