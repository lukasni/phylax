defmodule Phylax.Pathfinder.Config do
  @moduledoc false

  alias Phylax.Repo
  alias Phylax.Pathfinder.Config.Schema
  alias Phylax.EsiHelpers, as: ESI

  # import Ecto.Query

  def get_config(guild_id) do
    schema = Repo.get(Schema, guild_id) || %Schema{guild_id: guild_id}

    schema.data
  end

  def put_config(guild_id, config) do
    schema = Repo.get(Schema, guild_id) || %Schema{guild_id: guild_id}

    schema
    |> Schema.changeset(%{data: config})
    |> Repo.insert_or_update()
  end

  def set_default_chain(guild_id, map_name, root_system_name) do
    with {:ok, root_id} <- ESI.search({:system, root_system_name}),
         map_id when is_integer(map_id) <- Phylax.Pathfinder.Map.get_map_id(map_name) do
      set_default_chain(guild_id, {map_id, root_id})
    else
      {:error, :not_found} -> {:error, :system_not_found}
      nil -> {:error, :map_not_found}
      e -> e
    end
  end

  def set_default_chain(guild_id, {map_id, root_system_id}) do
    new_config =
      (get_config(guild_id) || %{})
      |> Map.put("default_map", map_id)
      |> Map.put("default_root", root_system_id)

    put_config(guild_id, new_config)
  end

  def get_default_chain(guild_id) do
    case get_config(guild_id) do
      %{"default_map" => map, "default_root" => root} ->
        {map, root}

      _ ->
        nil
    end
  end
end
