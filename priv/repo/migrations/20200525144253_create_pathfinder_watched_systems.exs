defmodule Phylax.Repo.Migrations.CreatePathfinderWatchedSystems do
  use Ecto.Migration

  def change do
    create table(:pathfinder_watched_systems) do
      add :user_id, :bigint
      add :system_id, :integer
      add :guild_id, :bigint

      timestamps()
    end
  end
end
