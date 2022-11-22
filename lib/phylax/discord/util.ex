defmodule Phylax.Discord.Util do
  @moduledoc """
  Various discord helpers
  """

  def prefix do
    Application.fetch_env!(:nosedrum, :prefix)
  end

  def usage(module) do
    usage("usage", module)
  end

  def usage(name, command_module) do
    [
      embed: %Nostrum.Struct.Embed{
        title: "❔ `#{name}`",
        description: """
        ```ini
        #{command_module.usage() |> Stream.map(&"#{prefix()}#{&1}") |> Enum.join("\n")}
        ```
        #{command_module.description()}
        """
      }
    ]
  end

  def has_required_args?(options, args) do
    Enum.all?(args, &Keyword.has_key?(options, &1))
  end

  def replace_fancy_quotes(msg) do
    msg
    |> Map.update!(:content, fn s -> String.replace(s, ~r/[“”]/, ~s(")) end)
  end
end
