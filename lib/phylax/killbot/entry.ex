defmodule Phylax.Killbot.Entry do
  use Ecto.Schema
  import Ecto.Changeset

  schema "killbot_entries" do
    field :channel_id, :integer
    field :entity_id, :integer
    field :entity_type, :string
    field :entity_name, :string

    timestamps()
  end

  @doc false
  def changeset(entry, attrs) do
    entry
    |> cast(attrs, [:channel_id, :entity_id, :entity_type, :entity_name])
    |> validate_required([:channel_id, :entity_id, :entity_type, :entity_name])
    |> unique_constraint([:channel_id, :entity_id])
  end
end
