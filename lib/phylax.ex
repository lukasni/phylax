defmodule Phylax do
  @moduledoc """
  Phylax keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  def broadcast(kill) do
    Phoenix.PubSub.broadcast(Phylax.PubSub, "killboard", {:kill, kill})
  end

  def subscribe(topic) do
    Phoenix.PubSub.subscribe(Phylax.PubSub, Atom.to_string(topic))
  end
end
