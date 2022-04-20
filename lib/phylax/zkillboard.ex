defmodule Phylax.Zkillboard do
  @api_url "https://zkillboard.com/api"

  def fetch(kill_id) do
    zkb =
      kill_id
      |> kill_url()
      |> get!(headers())
      |> Map.get(:body)
      |> Jason.decode!()
      |> hd()
      |> Map.get("zkb")
      |> IO.inspect()

    {:ok, esi, _meta} =
      kill_id
      |> ExEsi.API.Killmails.get(zkb["hash"])
      |> ExEsi.request()

    esi
    |> Map.put("zkb", zkb)
  end

  def kill_url(kill_id) do
    "#{@api_url}/kills/killID/#{kill_id}/"
  end

  def headers() do
    [
      {"User-Agent", Application.get_env(:ex_esi, :user_agent)}
    ]
  end

  defp get!(url, headers) do
    {:ok, result} =
      Finch.build(:get, url, headers)
      |> Finch.request(FinchClient)

    result
  end
end
