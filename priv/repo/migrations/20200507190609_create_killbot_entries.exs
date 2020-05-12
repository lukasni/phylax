defmodule Phylax.Repo.Migrations.CreateKillbotEntries do
  use Ecto.Migration

  def change do
    create table(:killbot_entries) do
      add :channel_id, :bigint
      add :entity_id, :bigint
      add :entity_type, :string
      add :entity_name, :string

      timestamps()
    end

    create unique_index(:killbot_entries, [:channel_id, :entity_id])
  end
end
