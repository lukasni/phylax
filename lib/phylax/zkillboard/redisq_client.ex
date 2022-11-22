defmodule Phylax.Zkillboard.RedisqClient do
  use GenServer

  require Logger

  alias Phylax.Core.Kill

  @name __MODULE__
  @killmail_url "https://zkillboard.com/kill"
  @initial_state %{
    tries: 0,
    last_result: nil,
    processed: 0
  }

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: @name)
  end

  def get_state() do
    GenServer.call(@name, :get_state, :timer.seconds(config()[:ttw]))
  end

  ##################
  # Server Callbacks
  ##################

  def init(_) do
    Process.send_after(self(), :next, :timer.seconds(config()[:ttw]))
    {:ok, @initial_state}
  end

  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  def handle_info(:next, state) do
    state =
      case process_response(fetch_next()) do
        {:ok, %Kill{} = result} ->
          Phylax.broadcast(result)

          state
          |> Map.update!(:processed, &(&1 + 1))
          |> Map.put(:tries, 0)
          |> Map.put(:last_result, result)

        {:ok, :empty_package} ->
          state

        {:error, {:rate_limiting, _} = result} ->
          state
          |> Map.update!(:tries, &(&1 + 1))
          |> Map.put(:last_result, result)

        {:error, result} ->
          %{state | last_result: result}
      end

    Process.send_after(self(), :next, backoff(state.tries))
    {:noreply, state}
  end

  def handle_info(_, state) do
    {:noreply, state}
  end

  ##################
  # Helper Functions
  ##################

  @doc """
  Processes the RedisQ response, returns a 3-tuple of the result type, result and the delay to next fetch.
  """
  def process_response(response) do
    with {:ok, %{body: body, status: 200}} <- response,
         {:ok, %{"package" => package}} <- Jason.decode(body),
         {:ok, killmail} <- extract_package(package),
         {:ok, kill} <- parse_killmail(killmail) do
      Logger.debug("Received Kill #{kill.kill_id}")
      {:ok, kill}
    else
      {:ok, %{status: 429} = response} ->
        {:error, {:rate_limiting, response}}

      :empty_package ->
        {:ok, :empty_package}

      error ->
        error
    end
  end

  def fetch_next(opts \\ []) do
    Finch.build(:get, uri_string(opts), headers())
    |> Finch.request(FinchClient)
  end

  def extract_package(nil), do: :empty_package

  def extract_package(%{"killID" => kill_id, "killmail" => killmail, "zkb" => zkb}) do
    # This should probably not be done here, but I really want to keep the clients compatible.
    zkb =
      zkb
      |> Map.put("url", "#{@killmail_url}/#{kill_id}/")

    {:ok, Map.put(killmail, "zkb", zkb)}
  end

  def parse_killmail(killmail) do
    try do
      {:ok, Kill.from_killmail(killmail)}
    rescue
      error ->
        {:error, {:invalid_killmail, killmail, error}}
    end
  end

  def uri_string(opts \\ []) do
    opts =
      Keyword.take(config(), [:ttw, :queueID])
      |> Keyword.merge(opts)

    config()[:base_url]
    |> URI.parse()
    |> Map.put(:query, URI.encode_query(opts))
    |> URI.to_string()
  end

  def headers() do
    [
      {"User-Agent", config()[:user_agent]}
    ]
  end

  def backoff(tries) do
    (config()[:ttw] * tries)
    |> min(60)
    |> :timer.seconds()
  end

  def config do
    Application.get_env(:phylax, __MODULE__)
  end
end
