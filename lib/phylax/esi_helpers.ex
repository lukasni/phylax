defmodule Phylax.EsiHelpers do
  alias ExEsi.API

  alias Phylax.Core.Kill

  require Logger

  @jspace_regions %{
    "A-" => "C1",
    "B-" => "C2",
    "C-" => "C3",
    "D-" => "C4",
    "E-" => "C5",
    "F-" => "C6",
    "G-" => "C12",
    "H-" => "C13"
  }

  def names(%Kill{} = kill) do
    kill.killmail
    |> name_ids()
    |> API.Universe.names()
    |> retry_404()
    |> remap_names()
  end

  def names([]) do
    %{}
  end

  def names(ids) when is_list(ids) do
    ids
    |> API.Universe.names()
    |> retry_404()
    |> remap_names()
  end

  def ids(names) when names == [] or is_nil(names) do
    []
  end

  def ids(names) do
    IO.inspect(names)
    {:ok, result, _meta} =
      names
      |> API.Universe.ids()
      |> ExEsi.request

    for {type, entries} <- result, entry <- entries do
      %{entity_id: entry["id"], entity_name: entry["name"], entity_type: singular_result_type(type)}
    end
  end

  def get_name(id) do
    [id]
    |> API.Universe.names()
    |> retry_404()
    |> pluck_name(id)
  end

  def location(%Kill{} = kill) do
    {:ok, system, _} =
      kill.system_id
      |> API.Universe.systems()
      |> ExEsi.request()

    {:ok, constellation, _} =
      system["constellation_id"]
      |> API.Universe.constellations()
      |> ExEsi.request()

    {:ok, region, _} =
      constellation["region_id"]
      |> API.Universe.regions()
      |> ExEsi.request()

    %{
      system: system,
      constellation: constellation,
      region: region,
      jspace: check_jspace(region)
    }
  end

  def search({:corporation, term}) do
    term
    |> API.Corporation.search()
    |> do_search()
  end

  def search({:alliance, term}) do
    term
    |> API.Alliance.search()
    |> do_search()
  end

  def search({:character, term}) do
    term
    |> API.Character.search()
    |> do_search()
  end

  def search({:system, term}) do
    term
    |> API.Search.public([:solar_system], true)
    |> API.put_after_parse(&Map.get(&1, "solar_system"))
    |> do_search()
  end

  defp do_search(op) do
    case ExEsi.request(op) do
      {:ok, [id], _} ->
        {:ok, id}

      {:ok, nil, _} ->
        {:error, :not_found}

      {:ok, _list, _} ->
        {:error, :ambiguous}

      {:error, {:http_error, 400, _}, _} ->
        {:error, :too_short}

      {:error, error} ->
        {:error, error}
    end
  end

  defp remap_names({:ok, names_result, _meta}) do
    names_result
    |> Enum.reduce(%{}, fn r, acc ->
      Map.put(acc, r["id"], %{
        name: r["name"],
        category: String.to_atom(r["category"]),
        id: r["id"]
      })
    end)
  end

  defp pluck_name({:ok, names_result, _meta}, id) do
    names_result
    |> Enum.find_value(fn x -> if x["id"] == id, do: x["name"], else: false end)
  end

  defp retry_404(op) do
    case ExEsi.request(op) do
      {:ok, _, _} = resp ->
        resp

      {:error, {:http_error, 404, _}, _} ->
        wait = max(100, :rand.uniform(500))
        Logger.warn("NAMES returned 404, retrying in #{wait} ms")
        :timer.sleep(wait)
        retry_404(op)
    end
  end

  defp name_ids(killmail) do
    [
      killmail["solar_system_id"],
      party_ids(killmail["victim"]),
      Enum.map(killmail["attackers"], &party_ids/1)
    ]
    |> List.flatten()
    |> Enum.uniq()
  end

  defp party_ids(party) do
    [
      party["character_id"],
      party["corporation_id"],
      party["alliance_id"],
      party["faction_id"],
      party["ship_type_id"]
      # party["weapon_type_id"]
    ]
    |> Enum.reject(&is_nil/1)
  end

  defp check_jspace(%{"name" => region_name}) do
    prefix = String.slice(region_name, 0..1)

    Map.get(@jspace_regions, prefix)
  end

  defp singular_result_type(plural)
  defp singular_result_type("alliances"), do: "alliance"
  defp singular_result_type("corporations"), do: "corporation"
  defp singular_result_type("characters"), do: "character"
  defp singular_result_type("factions"), do: "faction"
  defp singular_result_type(_), do: "other"
end
