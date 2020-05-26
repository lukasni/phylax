defmodule Phylax.Pathfinder.Config.Schema do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:guild_id, :integer, autogenerate: false}
  schema "pathfinder_config" do
    field :data, :map

    timestamps()
  end

  @doc false
  def changeset(config, attrs) do
    config
    |> cast(attrs, [:guild_id, :data])
    |> validate_required([:guild_id, :data])
  end
end
