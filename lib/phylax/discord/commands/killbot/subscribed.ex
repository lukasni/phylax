defmodule Phylax.Discord.Commands.Killbot.Subscribed do
  @moduledoc """
  `pf map` command definition
  """

  @behaviour Nosedrum.Command

  alias Nosedrum.Predicates
  alias Nostrum.Api
  alias Phylax.Discord.Util
  alias Phylax.Killbot, as: KB

  @impl true
  def usage, do: ["killboard subscribed"]

  @impl true
  def description() do
    """
    Show killboard entities currently tracked in this channel.
    """
  end

  @impl true
  def predicates, do: [&Predicates.guild_only/1, Predicates.has_permission(:manage_roles)]

  @impl true
  def command(msg, []) do
    response =
      case KB.list_entities(msg.channel_id) do
        [] -> "No tracked entities in this channel"
        chains -> format_entities(chains)
      end

    Api.create_message(msg.channel_id, response)
  end

  def command(msg, _arg) do
    response = Util.usage(__MODULE__)

    Api.create_message(msg.channel_id, response)
  end

  defp format_entities(entities) do
    """
    Currently tracking:

    #{Enum.group_by(entities, & &1.entity_type) |> Enum.map(&format_entity_group/1)}
    """
  end

  defp format_entity_group({group, entities}) do
    """
    **#{group |> to_string |> String.capitalize()}s**
    #{Enum.map(entities, & &1.entity_name) |> Enum.join(", ")}
    """
  end
end
