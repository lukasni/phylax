defmodule Phylax.Pathfinder.WatchedChain do
  use Ecto.Schema
  import Ecto.Changeset

  alias Phylax.Pathfinder.ExcludedEntity

  schema "pathfinder_watched_chains" do
    field :channel_id, :integer
    field :map_id, :integer
    field :root_system_id, :integer

    has_many :excluded_entities, ExcludedEntity

    timestamps()
  end

  @doc false
  def changeset(watched_chain, attrs) do
    watched_chain
    |> cast(attrs, [:channel_id, :map_id, :root_system_id])
    |> validate_required([:channel_id, :map_id, :root_system_id])
  end
end
