defmodule Phylax.Discord.Commands.Pathfinder.Config do
  @moduledoc """
  `pf config` command definition
  """

  @behaviour Nosedrum.Command

  @prefix Application.fetch_env!(:nosedrum, :prefix)

  alias Nostrum.Api
  alias Nosedrum.Predicates

  @impl true
  def usage,
    do: ["pf config <options...>"]

  @impl true
  def description() do
    """
    Pathfinder Config. Superusers can configure the default chain used for watchlists here.
    """
  end

  @impl true
  def predicates, do: [Predicates.has_permission(:manage_roles)]

  @impl true
  def command(msg, ["--default-chain", map_name, root_system_name]) do
    response =
      case Phylax.Pathfinder.Config.set_default_chain(msg.guild_id, map_name, root_system_name) do
        {:ok, _} ->
          "Default chain configured"

        {:error, error} ->
          "Error configuring chain: #{inspect(error)}"
      end

    Api.create_message(msg.channel_id, response)
  end

  def command(msg, arg) do
    IO.inspect(arg)

    response = """
    ℹ️ usage:
    ```ini
    #{
      usage()
      |> Stream.map(&"#{@prefix}#{&1}")
      |> Enum.join("\n")
    }
    ```
    """

    Api.create_message(msg.channel_id, response)
  end
end
