defmodule Phylax.Discord.Consumer.Ready do
  alias Nosedrum.Storage.ETS, as: CommandStorage
  alias Nostrum.Api
  alias Phylax.Discord.Commands

  @commands %{
    "help" => Commands.Help,
    "ping" => Commands.Ping,
    "pathfinder" => %{
      "subscribe" => Commands.Pathfinder.Subscribe,
      "subscribed" => Commands.Pathfinder.Subscribed,
      "unsubscribe" => Commands.Pathfinder.Unsubscribe,
      "watchlist" => Commands.Pathfinder.Watchlist,
      "config" => Commands.Pathfinder.Config
    },
    "killboard" => %{
      "subscribe" => Commands.Killbot.Subscribe,
      "subscribed" => Commands.Killbot.Subscribed,
      "unsubscribe" => Commands.Killbot.Unsubscribe
    }
  }

  @aliases %{
    "man" => Map.fetch!(@commands, "help"),
    "pf" => Map.fetch!(@commands, "pathfinder"),
    "kb" => Map.fetch!(@commands, "killboard")
  }

  @bot_prefix Application.fetch_env!(:nosedrum, :prefix)

  def handle(_data) do
    :ok = load_commands()
    :ok = Api.update_status(:online, "you | #{@bot_prefix}help", 2)
  end

  defp load_commands() do
    [@commands, @aliases]
    |> Stream.concat()
    |> Enum.each(fn {name, command} -> CommandStorage.add_command({name}, command) end)
  end
end
