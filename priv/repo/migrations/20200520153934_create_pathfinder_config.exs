defmodule Phylax.Repo.Migrations.CreatePathfinderConfig do
  use Ecto.Migration

  def change do
    create table(:pathfinder_config, primary_key: false) do
      add :guild_id, :bigint, primary_key: true
      add :data, :map

      timestamps()
    end

    create unique_index(:pathfinder_config, [:guild_id])
  end
end
