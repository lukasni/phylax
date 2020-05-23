defmodule Phylax.Repo.Migrations.CreatePathfinderWatchedChains do
  use Ecto.Migration

  def change do
    create table(:pathfinder_watched_chains) do
      add :channel_id, :bigint
      add :map_id, :integer
      add :root_system_id, :integer

      timestamps()
    end
  end
end
