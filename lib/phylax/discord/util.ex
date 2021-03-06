defmodule Phylax.Discord.Util do
  @moduledoc """
  Various discord helpers
  """

  @prefix Application.fetch_env!(:nosedrum, :prefix)

  def usage(module) do
    """
    ℹ️ usage:
    ```ini
    #{
      module.usage()
      |> Stream.map(&"#{@prefix}#{&1}")
      |> Enum.join("\n")
    }
    ```
    """
  end

  def has_required_args?(options, args) do
    Enum.all?(args, &Keyword.has_key?(options, &1))
  end
end
