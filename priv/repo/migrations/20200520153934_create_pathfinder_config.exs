defmodule Phylax.Repo.Migrations.CreatePathfinderConfig do
  use Ecto.Migration

  def change do
    create table(:pathfinder_config) do
      add :guild_id, :bigint
      add :data, :map

      timestamps()
    end

    create unique_index(:pathfinder_config, [:guild_id])
  end
end
