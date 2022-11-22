defmodule Phylax.Discord.Commands.Help do
  @moduledoc """
  `help` command definition
  """

  @behaviour Nosedrum.Command

  alias Nosedrum.Storage.ETS, as: CommandStorage
  alias Nosedrum.Helpers
  alias Nostrum.Api
  alias Nostrum.Struct.Embed
  alias Phylax.Discord.Util

  @impl true
  def usage, do: ["help [command:str]", "help [command_group:str] [subcommand_name:str]"]

  @impl true
  def description do
    """
    Show information about the given command.
    With no arguments given, list all commands.
    """
  end

  @impl true
  def predicates, do: []

  @impl true
  def command(msg, []) do
    embed = %Embed{
      title: "Available commands",
      description:
        CommandStorage.all_commands()
        |> Map.keys()
        |> Stream.map(&"`#{Util.prefix()}#{&1}`")
        |> (fn commands ->
              """
              #{Enum.join(commands, ", ")}
              """
            end).()
    }

    {:ok, _msg} = Api.create_message(msg.channel_id, embed: embed)
  end

  def command(msg, [command_name]) do
    case CommandStorage.lookup_command(command_name) do
      nil ->
        response = "🚫 unknown command, check `help` to view all"
        {:ok, _msg} = Api.create_message(msg.channel_id, response)

      command_module when not is_map(command_module) ->
        embed = Util.usage(command_name, command_module)
        {:ok, _msg} = Api.create_message(msg.channel_id, embed)

      subcommand_map ->
        embed =
          if Map.has_key?(subcommand_map, :default) do
            Util.usage(command_name, subcommand_map.default)
          else
            subcommand_string =
              subcommand_map
              |> format_subcommand_list()

            [
              embed: %Embed{
                title: "`#{command_name}` - subcommands",
                description: subcommand_string,
                footer: %Embed.Footer{
                  text: "View `help #{command_name} <subcommand>` for details"
                }
              }
            ]
          end

        {:ok, _msg} = Api.create_message(msg.channel_id, embed)
    end
  end

  def command(msg, [command_group, subcommand_name]) do
    with command_map when is_map(command_map) <- CommandStorage.lookup_command(command_group),
         {:ok, command_module} <- Map.fetch(command_map, subcommand_name) do
      embed = Util.usage("#{command_group} #{subcommand_name}", command_module)
      {:ok, _msg} = Api.create_message(msg.channel_id, embed)
    else
      :error ->
        subcommand_string =
          CommandStorage.lookup_command(command_group)
          |> format_subcommand_list()

        response =
          "🚫 unknown subcommand `#{Helpers.escape_server_mentions(subcommand_name)}`, " <>
            "known commands: #{subcommand_string}"

        {:ok, _msg} = Api.create_message(msg.channel_id, response)

      nil ->
        response =
          "🚫 no command group named `#{Helpers.escape_server_mentions(command_group)}` found"

        {:ok, _msg} = Api.create_message(msg.channel_id, response)

      _ ->
        response =
          "🚫 that command has no subcommands, use `help #{command_group}` for information on it"

        {:ok, _msg} = Api.create_message(msg.channel_id, response)
    end
  end

  def command(msg, _args) do
    response = Util.usage(__MODULE__)

    Api.create_message(msg.channel_id, response)
  end

  defp format_subcommand_list(subcommands) do
    subcommands
    |> Map.keys()
    |> Stream.reject(&(&1 === :default))
    |> Stream.map(&"`#{&1}`")
    |> Enum.join(", ")
  end
end
