defmodule Phylax.Discord.Commands.Killbot.Subscribe do
  @moduledoc """
  `pf map` command definition
  """

  @behaviour Nosedrum.Command

  require Logger

  alias Nosedrum.Predicates
  alias Nosedrum.Helpers
  alias Nostrum.Api
  alias Phylax.Discord.Util
  alias Phylax.Killbot
  alias Phylax.EsiHelpers, as: ESI

  @impl true
  def usage, do: ["killbot subscribe [options"]

  @impl true
  def description() do
    """
    Subscribe to receive kills from corps / alliances
    """
  end

  @impl true
  def predicates, do: [&Predicates.guild_only/1, Predicates.has_permission(:manage_roles)]

  @impl true
  def command(msg, opts) do
    {entities, _rest, _invalid} =
      OptionParser.parse(opts,
        strict: [corporation: :keep, alliance: :keep],
        aliases: [c: :corporation, a: :alliance]
      )

    results = search_and_add(entities, msg.channel_id)

    response =
      case results.error do
        [] ->
          "All entities added successfully."

        errors ->
          "Some entites could not be added:\n" <> format_errors(errors)
      end

    Api.create_message(msg.channel_id, response)
  end

  defp search_and_add(entities, channel_id) do
    entities
    |> Task.async_stream(fn e -> {ESI.search(e), e} end)
    |> Enum.reduce(%{success: [], error: []}, &reduce_search_result(&1, &2, channel_id))
  end

  defp reduce_search_result({task_res, {search_res, {type, name}}}, acc, channel_id) do
    with :ok <- task_res,
         {:ok, id} <- search_res,
         {:ok, _} <-
           Killbot.subscribe(
             entity_id: id,
             channel_id: channel_id,
             entity_type: to_string(type),
             entity_name: name
           ) do
      Map.update!(acc, :success, &[{id, type, name} | &1])
    else
      :error ->
        Map.update!(acc, :error, &[{name, :task_error} | &1])

      {:error, result} ->
        Map.update!(acc, :error, &[{name, result} | &1])
    end
  end

  defp format_errors(errors) do
    errors
    |> Enum.reduce("", fn {name, error}, acc ->
      acc <> "**#{name}** - #{pretty_print_search_error(error)}\n"
    end)
  end

  defp pretty_print_search_error(:not_found), do: "No result found"
  defp pretty_print_search_error(:too_short), do: "Search term too short"
  defp pretty_print_search_error(:ambiguous), do: "Ambiguous search result"

  defp pretty_print_search_error(%Ecto.Changeset{}),
    do: "Already watching this entity in this channel"

  defp pretty_print_search_error(error) do
    Logger.warn("KILLBOT ADD: #{inspect(error)}")
    "Unexpected error"
  end
end
