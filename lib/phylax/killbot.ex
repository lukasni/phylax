defmodule Phylax.Killbot do
  @moduledoc """
  The Killbot module provides a kill feed for discord channels, powered by Zkillboard.

  This context module offers functions for subscribing and unsubscribing corporations
  and alliances from individual channels.

  This module also provides functions for manipulating Killbot entries in the database.
  """
  alias Phylax.Repo
  alias Phylax.Killbot.Entry
  import Ecto.Query

  @doc """
  Start tracking kills and losses for a corporation or alliance in a channel.

  Expects a keyword list with the following options:

  entity_id: int, EVE ID of the watched entity,
  channel_id: int, ID of the subscribing channel,
  entity_type: string, corporation or alliance,
  entity_name: string, human-readable name of the entity
  """
  def subscribe(opts) when is_list(opts) do
    create_entry(Map.new(opts))
    Phylax.Killbot.Manager.subscribe(opts[:channel_id], opts[:entity_id])
  end

  @doc """
  Stop tracking kills and losses for a corporation or alliance in a channel.

  Expects an %Entry{}
  """
  def unsubscribe(%Entry{} = entry) do
    delete_entry(entry)
    Phylax.Killbot.Manager.unsubscribe(entry.channel_id, entry.entity_id)
  end

  @doc """
  List all channels in all guilds with an active killbot subscription.
  """
  def channels() do
    from(e in Entry, distinct: true, select: e.channel_id)
    |> Repo.all()
  end

  @doc """
  List all watched entities in a single channel
  """
  def list_entities(channel_id) do
    channel_id
    |> entry_by_channel_id()
    |> Repo.all()
  end

  @doc """
  List all watched entitites in all channels
  """
  def list_entities() do
    Entry
    |> Repo.all()
  end

  @doc """
  Create a new killbot entry
  """
  def create_entry(args) do
    %Entry{}
    |> Entry.changeset(args)
    |> Repo.insert()
  end

  @doc """
  Get a watched entity in a channel by its name. Used for the delete command.
  """
  def get_entry(channel_id, name) when is_binary(name) do
    Repo.one(from e in entry_by_channel_id(channel_id), where: e.entity_name == ^name)
  end

  @doc """
  Delete a single killbot entry
  """
  def delete_entry(entry) do
    entry
    |> Repo.delete()
  end

  defp entry_by_channel_id(channel_id) do
    from e in Entry,
      where: e.channel_id == ^channel_id
  end
end
