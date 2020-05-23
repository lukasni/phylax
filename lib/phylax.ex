defmodule Phylax do
  @moduledoc """
  Phylax keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  alias Phylax.Core.Kill

  def broadcast(%Kill{} = kill) do
    Phoenix.PubSub.broadcast(Phylax.PubSub, "killboard", {:kill, kill})
  end

  def subscribe(topic) when is_atom(topic) do
    subscribe(to_string(topic))
  end

  def subscribe(topic) when is_binary(topic) do
    Phoenix.PubSub.subscribe(Phylax.PubSub, topic)
  end
end
