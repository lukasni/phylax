defmodule Phylax.Pathfinder.Chain do
  @moduledoc false

  def connected_systems(%Graph{} = map, root_system_id) do
    Graph.reachable(map, [root_system_id])
    |> Enum.reject(&is_nil/1)
    |> MapSet.new()
  end

  def check_updated_connections(old_connections, new_connections) do
    case new_connections == old_connections do
      false ->
        {:updated,
         %{
           added: MapSet.difference(new_connections, old_connections),
           removed: MapSet.difference(old_connections, new_connections)
         }}

      true ->
        :unchanged
    end
  end

  def route({map_id, root_system_id} = _chain, system) do
    map = Phylax.Pathfinder.Map.Worker.get_map(map_id)

    Graph.get_shortest_path(map, root_system_id, system)
    |> Enum.map(fn s -> label_system(s, map) end)
  end

  defp label_system(system_id, map) do
    label = Graph.vertex_labels(map, system_id) |> hd() |> String.trim()

    case label do
      "" ->
        Phylax.EsiHelpers.get_name(system_id)

      label ->
        label
    end
  end
end
