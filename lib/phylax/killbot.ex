defmodule Phylax.Killbot do
  alias Phylax.Repo
  alias Phylax.Killbot.Entry
  import Ecto.Query

  def list_entities() do
    Entry
    |> Repo.all()
  end

  def list_entities(channel_id) do
    channel_id
    |> entry_by_channel_id()
    |> Repo.all()
  end

  def create_entry(args) do
    %Entry{}
    |> Entry.changeset(args)
    |> Repo.insert()
  end

  def get_entry(channel_id, name) when is_binary(name) do
    Repo.one(from e in entry_by_channel_id(channel_id), where: e.entity_name == ^name)
  end

  def delete_entry(entry) do
    entry
    |> Repo.delete()
  end

  def channels() do
    from(e in Entry, distinct: true, select: e.channel_id)
    |> Repo.all()
  end

  def subscribe(opts) when is_list(opts) do
    Phylax.Killbot.Manager.subscribe(opts[:channel_id], opts[:entity_id])
    create_entry(Map.new(opts))
  end

  def unsubscribe(%Entry{} = entry) do
    delete_entry(entry)
    Phylax.Killbot.Manager.unsubscribe(entry.channel_id, entry.entity_id)
  end

  defp entry_by_channel_id(channel_id) do
    from e in Entry,
    where: e.channel_id == ^channel_id
  end
end
