defmodule Phylax.Discord.Embeds.Kill do
  @moduledoc false

  @zkb_url "https://zkillboard.com"

  alias Phylax.Core.Kill
  import Nostrum.Struct.Embed

  @colors %{
    kill: 0x36A64F,
    loss: 0xD00000,
    neural: 0x808080
  }

  def build(%Kill{killmail: killmail} = kill, opts) do
    names = Keyword.get(opts, :names)
    location = Keyword.get(opts, :location)
    type = Keyword.get(opts, :type, :neutral)
    victim = kill.killmail["victim"]

    %Nostrum.Struct.Embed{}
    |> put_type("rich")
    |> put_title(kill_title(kill, names, type))
    |> put_url(kill.url)
    |> put_field("Victim", print_party(victim, names))
    |> put_field("Final Blow", "#{print_party(get_killer(kill), names)}")
    |> put_field("Damage Taken", format_damage(victim), true)
    |> put_field("Pilots involved", to_string(length(killmail["attackers"])), true)
    |> put_field("Value", format_number(killmail["zkb"]["totalValue"]), true)
    |> put_field("Attackers", format_top_damage(kill, names))
    |> put_field("System", format_location(location))
    |> put_thumbnail("https://images.evetech.net/types/#{victim["ship_type_id"]}/render?size=64")
    |> put_timestamp(killmail["killmail_time"])
    |> put_color(@colors[type])
  end

  defp kill_title(kill, names, type) do
    case type do
      :loss -> "Loss: #{names[kill.killmail["victim"]["ship_type_id"]][:name]}"
      _ -> "Kill: #{names[kill.killmail["victim"]["ship_type_id"]][:name]}"
    end
  end

  defp get_killer(kill) do
    kill.killmail["attackers"]
    |> Enum.find(nil, & &1["final_blow"])
  end

  defp get_most_damage(kill, amount) do
    kill.killmail["attackers"]
    |> Enum.sort_by(& &1["damage_done"], :desc)
    |> Enum.take(amount)
  end

  defp party_name(party, names) do
    id =
      party["character_id"] ||
        party["ship_type_id"]

    case names[id] do
      %{category: :inventory_type} = name ->
        %{name | category: :ship}

      name ->
        name
    end
  end

  defp party_affiliation(party, names) do
    id =
      party["corporation_id"] ||
        party["faction_id"]

    names[id]
  end

  defp party_alliance(party, names) do
    case party["alliance_id"] do
      nil ->
        nil

      id ->
        names[id]
    end
  end

  defp print_party(party, names) do
    name = party_name(party, names)
    affil = party_affiliation(party, names)

    case party_alliance(party, names) do
      nil ->
        "#{format_ship(party, names)}: #{format_link(name)} (#{format_link(affil)})"

      alliance ->
        "#{format_ship(party, names)}: #{format_link(name)} (#{format_link(alliance)})"
    end
  end

  defp format_link(nil), do: ":question:"

  defp format_link(name) do
    format_link(name.name, name)
  end

  defp format_link(text, entity) do
    "[#{text}](#{zkb_link(entity)})"
  end

  defp format_ship(%{"ship_type_id" => id}, names) do
    format_link(names[id].name, %{category: :ship, id: id})
  end

  defp format_ship(_, _) do
    ":question:"
  end

  defp format_damage(party) do
    (party["damage_taken"] || party["damage_done"])
    |> format_number()
  end

  defp format_number(damage) do
    Number.Delimit.number_to_delimited(damage, precision: 0, delimiter: ",")
  end

  defp format_top_damage(kill, names) do
    top = get_most_damage(kill, 5)

    Enum.map(top, &"#{print_party(&1, names)} (#{format_damage(&1)})")
    |> Enum.join("  \n")
  end

  defp format_location(%{jspace: nil} = location) do
    "#{print_system(location.system)} (#{format_security_status(location.system)}) / #{print_region(location.region)}"
  end

  defp format_location(location) do
    "#{print_system(location.system)} (#{location.jspace}) / #{print_region(location.region)}"
  end

  defp format_security_status(system) do
    Number.Delimit.number_to_delimited(system["security_status"], separator: ".", precision: 2)
  end

  defp print_system(system) do
    format_link(system["name"], %{category: :system, id: system["system_id"]})
  end

  defp print_region(region) do
    format_link(region["name"], %{category: :region, id: region["region_id"]})
  end

  defp zkb_link(%{category: :character, id: id}), do: "#{@zkb_url}/character/#{id}/"
  defp zkb_link(%{category: :corporation, id: id}), do: "#{@zkb_url}/corporation/#{id}/"
  defp zkb_link(%{category: :alliance, id: id}), do: "#{@zkb_url}/alliance/#{id}/"
  defp zkb_link(%{category: :faction, id: id}), do: "#{@zkb_url}/faction/#{id}/"
  defp zkb_link(%{category: :ship, id: id}), do: "#{@zkb_url}/ship/#{id}/"
  defp zkb_link(%{category: :system, id: id}), do: "#{@zkb_url}/system/#{id}/"
  defp zkb_link(%{category: :region, id: id}), do: "#{@zkb_url}/region/#{id}/"
end
