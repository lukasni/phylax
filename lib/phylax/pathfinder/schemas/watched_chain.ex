defmodule Phylax.Pathfinder.WatchedChain do
  use Ecto.Schema
  import Ecto.Changeset

  schema "pathfinder_watched_chains" do
    field :channel_id, :integer
    field :map_id, :integer
    field :root_system_id, :integer

    has_many :excluded_entities, Phylax.Pathfinder.ExcludedEntity

    timestamps()
  end

  @doc false
  def changeset(watched_chain, attrs) do
    watched_chain
    |> cast(attrs, [:channel_id, :map_id, :root_system_id])
    |> cast_assoc(:excluded_entities)
    |> validate_required([:channel_id, :map_id, :root_system_id])
  end
end
