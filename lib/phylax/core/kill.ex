defmodule Phylax.Core.Kill do
  defstruct ~w[kill_id system_id url affiliated in_chains killmail]a

  @defaults affiliated: %{},
            in_chains: MapSet.new()

  require Logger

  @doc """
  Create a new `%Kill{}` struct with default values and overrides
  """
  def new(fields \\ []) do
    fields =
      @defaults
      |> Keyword.merge(fields)

    struct(__MODULE__, fields)
  end

  @doc """
  Create a new `%Kill{}` struct from a JSON killmail from zkillboard
  """
  def from_killmail(killmail) do
    new(
      kill_id: killmail["killmail_id"],
      system_id: killmail["solar_system_id"],
      url: killmail["zkb"]["url"],
      affiliated: affiliated(killmail),
      killmail: killmail
    )
  end

  defp affiliated(%{"victim" => victim, "attackers" => attackers}) do
    victim_affiliations = MapSet.new(character_affiliations(victim))

    killer_affiliations =
      Enum.flat_map(attackers, &character_affiliations/1)
      |> MapSet.new()

    %{victim: victim_affiliations, killers: killer_affiliations}
  end

  defp character_affiliations(party) do
    result = [Map.get(party, "character_id", [])]
    result = [Map.get(party, "corporation_id", []) | result]
    result = [Map.get(party, "alliance_id", []) | result]
    result = [Map.get(party, "faction_id", []) | result]
    List.flatten(result)
  end
end
