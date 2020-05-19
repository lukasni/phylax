defmodule Phylax.Pathfinder.Chain do
  @moduledoc false

  def connected_systems(%Graph{} = map, root_system_id) do
    Graph.reachable(map, [root_system_id])
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
end
