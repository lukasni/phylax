defmodule Phylax.Pathfinder.Map do
  @moduledoc """
  This GenServer keeps a Map updated from Pathfinder.

  It keeps the following state:

  ```elixir
  %{
    map_id: integer
    graph: %Graph{}
  }
  ```

  `:map_id` is the pathfinder indernal ID of the map
  `:graph` is a Graph containing all active systems and connections fetched from Pathfinder for that map.
  """
  import Ecto.Query

  alias Phylax.Pathfinder.Repo

  def get_map_id(name) do
    from(m in "map",
      where: m.name == ^name,
      select: m.id
    )
    |> Repo.one()
  end

  def get_map_name(id) do
    from(m in "map",
      where: m.id == ^id,
      select: m.name
    )
    |> Repo.one()
  end

  def get_system_alias(map_id, system_id) do
    from(s in "system",
      where: s.mapId == ^map_id,
      where: s.systemId == ^system_id,
      select: s.alias
    )
    |> Repo.one()
  end

  def get_connections(map_id) do
    from(c in "connection",
      join: src in "system",
      on: [id: c.source],
      join: dst in "system",
      on: [id: c.target],
      where: c.mapId == ^map_id,
      select: {src.systemId, dst.systemId}
    )
    |> Repo.all()
  end

  def get_active_systems(map_id) do
    from(s in "system",
      where: s.mapId == ^map_id,
      where: s.active == 1,
      select: {s.systemId, s.alias}
    )
    |> Repo.all()
  end

  def build_map(map_id) do
    systems = get_active_systems(map_id)
    connections = get_connections(map_id) |> bidirectional()

    Graph.new(type: :directed)
    |> label_systems(systems)
    |> Graph.add_edges(connections)
  end

  def changed?(nil, _), do: true

  def changed?(old_map, new_map) do
    old_map.edges != new_map.edges
  end

  defp bidirectional(connections) do
    connections
    |> Enum.reduce(connections, fn {a, b}, acc -> [{b, a} | acc] end)
  end

  defp label_systems(graph, systems) do
    systems
    |> Enum.reduce(graph, fn {v, l}, graph ->
      Graph.add_vertex(graph, v, l)
    end)
  end
end
