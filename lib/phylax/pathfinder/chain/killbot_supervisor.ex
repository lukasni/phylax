defmodule Phylax.Pathfinder.Chain.KillbotSupervisor do
  @moduledoc false

  use DynamicSupervisor
  alias Phylax.Phylax.Chain.Killbot

  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_child(opts) do
    DynamicSupervisor.start_child(
      __MODULE__,
      %{id: Killbot, start: {Killbot, :start_link, [opts]}, restart: :transient}
    )
  end
end
