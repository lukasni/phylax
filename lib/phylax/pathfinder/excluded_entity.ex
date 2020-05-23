defmodule Phylax.Pathfinder.ExcludedEntity do
  use Ecto.Schema
  import Ecto.Changeset

  schema "pathfinder_excluded_entities" do
    field :entity_id, :integer
    field :entity_name, :string
    field :entity_type, :string

    belongs_to :watched_chain, Phylax.Pathfinder.WatchedChain

    timestamps()
  end

  @doc false
  def changeset(excluded_entity, attrs) do
    excluded_entity
    |> cast(attrs, [:entity_id, :entity_name, :entity_type, :watched_chain_id])
    |> validate_required([:entity_id, :entity_name, :entity_type])
  end
end
