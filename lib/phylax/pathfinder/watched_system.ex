defmodule Phylax.Pathfinder.WatchedSystem do
  use Ecto.Schema
  import Ecto.Changeset

  schema "pathfinder_watched_systems" do
    field :system_id, :integer
    field :user_id, :integer
    field :guild_id, :integer

    timestamps()
  end

  @doc false
  def changeset(watched_system, attrs) do
    watched_system
    |> cast(attrs, [:user_id, :system_id, :guild_id])
    |> validate_required([:user_id, :system_id, :guild_id])
  end
end
