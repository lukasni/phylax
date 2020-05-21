defmodule Phylax.Pathfinder do
  alias Phylax.Pathfinder.Chain
  alias Phylax.Pathfinder.WatchedChain
  alias Phylax.Repo
  import Ecto.Query
  alias Phylax.EsiHelpers, as: ESI

  @excluded_systems [
    # Jita
    30000142
  ]

  @doc """
  Get all watched chains from the config cache
  """
  @spec get_watched_chains :: [Chain.t()]
  def get_watched_chains() do
    WatchedChain
    |> Repo.all()
  end

  @doc """
  Get all watched chains for a specific discord channel
  """
  @spec get_watched_chains(integer()) :: [Chain.t()]
  def get_watched_chains(channel_id) do
    from(c in WatchedChain, where: c.channel_id == ^channel_id)
    |> Repo.all()
    |> Repo.preload(:excluded_entities)
  end

  @spec add_watched_chain(integer(), String.t(), String.t()) ::
          {:ok, any} | {:error, :map_not_found | :system_not_found | :unhandled}
  def add_watched_chain(channel_id, map_name, root_system_name) do
    with {:ok, root_id} <- ESI.search({:system, root_system_name}),
         map_id when is_integer(map_id) <- Phylax.Pathfinder.Map.get_map_id(map_name) do
      %WatchedChain{}
      |> WatchedChain.changeset(%{
        map_id: map_id,
        root_system_id: root_id,
        channel_id: channel_id
      })
      |> Repo.insert()
    else
      {:error, :not_found} -> {:error, :system_not_found}
      {_, nil} -> {:error, :map_not_found}
      _ -> {:error, :unhandled}
    end
  end

  def delete_watched_chain(channel_id, map_name, root_system_name) do
    with {:ok, root_id} <- ESI.search({:system, root_system_name}),
         map_id when is_integer(map_id) <- Phylax.Pathfinder.Map.get_map_id(map_name) do
      from(c in WatchedChain,
        where: c.map_id == ^map_id,
        where: c.root_system_id == ^root_id,
        where: c.channel_id == ^channel_id
      )
      |> Repo.delete()
    else
      {:error, :not_found} -> {:error, :system_not_found}
      nil -> {:error, :map_not_found}
      e -> e
    end
  end

  def delete_watched_chains(channel_id) do
    from(c in WatchedChain, where: c.channel_id == ^channel_id)
    |> Repo.delete()
  end

  def kill_in_chain?(kill, chain) do
    systems = Phylax.Pathfinder.Chain.Worker.get_connections(chain)

    (kill.system_id in systems) and (kill.system_id not in @excluded_systems)
  end

  def excluded?(kill, excludes) do
    (MapSet.disjoint?(kill.affiliated.killers, excludes) &&
       MapSet.disjoint?(kill.affiliated.victim, excludes)) == false
  end

  def broadcast({key, data}) do
    Phoenix.PubSub.broadcast(Phylax.PubSub, "pathfinder", {key, data})
  end

  def subscribe do
    Phoenix.PubSub.subscribe(Phylax.PubSub, "pathfinder")
  end
end
