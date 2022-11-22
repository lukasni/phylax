defmodule Phylax.Killbot.WorkerSupervisor do
  @moduledoc """
  Dynamic Supervisor process for the killbot workers, will restart any crashed worker processes
  """

  use DynamicSupervisor
  alias Phylax.Killbot.Worker

  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_child(opts) do
    DynamicSupervisor.start_child(
      __MODULE__,
      %{id: Worker, start: {Worker, :start_link, [opts]}, restart: :transient}
    )
  end
end
