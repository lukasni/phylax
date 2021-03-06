defmodule Phylax.Repo.Migrations.CreatePathfinderExcludedEntities do
  use Ecto.Migration

  def change do
    create table(:pathfinder_excluded_entities) do
      add :entity_id, :integer
      add :entity_name, :string
      add :entity_type, :string
      add :watched_chain_id, references(:pathfinder_watched_chains, on_delete: :delete_all)

      timestamps()
    end

    create index(:pathfinder_excluded_entities, [:watched_chain_id])
  end
end
