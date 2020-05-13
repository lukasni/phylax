defmodule Phylax.Discord.ConsumerSupervisor do
  use Supervisor

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init(_args) do
    children =
      for n <- 1..System.schedulers_online() do
        Supervisor.child_spec({Phylax.Discord.Consumer, []}, id: {:phylax, :consumer, n})
      end

    Supervisor.init(children, strategy: :one_for_one)
  end
end
