defmodule Phylax.Killbot.DiscordEmbed do
  @moduledoc false

  @zkb_url "https://zkillboard.com"

  alias Phylax.Core.Kill
  import Nostrum.Struct.Embed

  @colors %{
    kill: 0x36A64F,
    loss: 0xD00000,
    neural: 0x808080
  }

  def build(kill, opts) do
    names = Keyword.get(opts, :names)
    location = Keyword.get(opts, :location)
    type = Keyword.get(opts, :type, :neutral)

    %Nostrum.Struct.Embed{}
    |> put_type("rich")
    |> put_title(kill_title(kill, names))
    |> put_url(kill.url)
    |> put_description(kill_description(kill, names))
    |> put_field("Damage Taken", format_damage(kill.killmail["victim"]), true)
    |> put_field("Pilots involved", to_string(length(kill.killmail["attackers"])), true)
    |> put_field("Value", format_number(kill.killmail["zkb"]["totalValue"]), true)
    |> put_field("Ship", format_ship(kill.killmail["victim"], names))
    |> put_field("Most Damage", format_top_damage(kill, names))
    |> put_field("System", format_location(location))
    |> put_thumbnail("https://images.evetech.net/types/#{kill.killmail["victim"]["ship_type_id"]}/render?size=64")
    |> put_timestamp(kill.killmail["killmail_time"])
    |> put_color(@colors[type])
  end

  defp kill_title(kill, names) do
    "Kill: #{names[kill.killmail["victim"]["ship_type_id"]][:name]}"
  end

  defp kill_description(kill, names) do
    killer = get_killer(kill)
    victim = kill.killmail["victim"]

    "#{print_party(killer, names)} killed #{print_party(victim, names)}"
  end

  defp get_killer(kill) do
    kill.killmail["attackers"]
    |> Enum.find(nil, & &1["final_blow"])
  end

  defp get_most_damage(kill) do
    kill.killmail["attackers"]
    |> Enum.max_by(& &1["damage_done"])
  end

  defp party_name(party, names) do
    id =
      party["character_id"]
      || party["ship_type_id"]

    case names[id] do
      %{category: :inventory_type} = name ->
        %{name | category: :ship}

      name ->
        name
    end
  end

  defp party_affiliation(party, names) do
    id =
      party["corporation_id"]
      || party["faction_id"]

    names[id]
  end

  defp print_party(party, names) do
    name = party_name(party, names)
    affil = party_affiliation(party, names)
    "[#{name.name}](#{zkb_link(name)}) ([#{affil.name}](#{zkb_link(affil)}))"
  end

  defp format_ship(%{"ship_type_id" => id}, names) do
    "[#{names[id].name}](#{zkb_link(%{category: :ship, id: id})})"
  end

  defp format_damage(party) do
    (party["damage_taken"] || party["damage_done"])
    |> format_number()
  end

  defp format_number(damage) do
    Number.Delimit.number_to_delimited(damage, precision: 0, delimiter: ",")
  end

  defp format_top_damage(kill, names) do
    top = get_most_damage(kill)

    "#{print_party(top, names)} (#{format_damage(top)})"
  end

  defp format_location(%{jspace: nil} = location) do
    "#{print_system(location.system)} (#{Number.Delimit.number_to_delimited(location.system["security_status"], separator: ".", precision: 2)}) / #{print_region(location.region)}"
  end

  defp format_location(location) do
    "#{print_system(location.system)} (#{location.jspace}) / #{print_region(location.region)}"
  end

  defp print_system(system) do
    "[#{system["name"]}](#{zkb_link(%{category: :system, id: system["system_id"]})})"
  end

  defp print_region(region) do
    "[#{region["name"]}](#{zkb_link(%{category: :region, id: region["region_id"]})})"
  end

  defp zkb_link(%{category: :character, id: id}), do: "#{@zkb_url}/character/#{id}/"
  defp zkb_link(%{category: :corporation, id: id}), do: "#{@zkb_url}/corporation/#{id}/"
  defp zkb_link(%{category: :alliance, id: id}), do: "#{@zkb_url}/alliance/#{id}/"
  defp zkb_link(%{category: :faction, id: id}), do: "#{@zkb_url}/faction/#{id}/"
  defp zkb_link(%{category: :ship, id: id}), do: "#{@zkb_url}/ship/#{id}/"
  defp zkb_link(%{category: :system, id: id}), do: "#{@zkb_url}/system/#{id}/"
  defp zkb_link(%{category: :region, id: id}), do: "#{@zkb_url}/region/#{id}/"
end
