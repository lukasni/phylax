defmodule Phylax.Zkillboard.RedisqClient do
  use GenServer

  require Logger

  alias Phylax.Core.Kill

  @name __MODULE__
  @base_url "https://redisq.zkillboard.com/listen.php"
  @killmail_url "https://zkillboard.com/kill"
  @queue_id "NVACA-Phylax-#{Mix.env()}"

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: @name)
  end

  def get_state() do
    GenServer.call(@name, :get_state)
  end

  ##################
  # Server Callbacks
  ##################

  def init(_) do
    send(self(), :next)
    {:ok, 0}
  end

  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  def handle_info(:next, state) do
    state =
      case process_response(fetch_next()) do
        %Kill{} ->
          state + 1

        _ ->
          state
      end

    send(self(), :next)
    {:noreply, state}
  end

  def handle_info(_, state) do
    {:noreply, state}
  end

  ##################
  # Helper Functions
  ##################

  def process_response(response) do
    with {:ok, %{body: body, status_code: 200}} <- response,
         {:ok, %{"package" => package}} <- Jason.decode(body),
         {:ok, killmail} <- extract_package(package),
         {:ok, kill} <- parse_killmail(killmail) do
      Logger.debug("Received Kill #{kill.kill_id}")
      Phylax.broadcast(kill)
      kill
    else
      {:ok, %{status_code: 429} = response} ->
        Logger.info("Rate Limiting: #{inspect response}")
        Logger.info("Sleeping for 10 seconds")
        :timer.sleep(:timer.seconds(10))

      {:error, %HTTPoison.Error{} = error} ->
        Logger.info("HTTP Error: #{inspect error}")

      {:error, %Jason.DecodeError{} = error} ->
        Logger.info("Decode Error: #{inspect error}\n\nResponse: #{inspect response}")

      {:error, :empty_package} ->
        Logger.debug("Empty package. No killmails in past 10 seconds")

      {:error, {:invalid_killmail, killmail, error}} ->
        Logger.info("Invalid Killmail: #{inspect killmail}. Raised error: #{inspect error}")

      error ->
        Logger.info("Unexpected error handling killmail: #{inspect error}")
    end
  end

  def fetch_next(opts \\ []) do
    uri_string(opts)
    |> HTTPoison.get(headers(), recv_timeout: 15_000)
  end

  def extract_package(nil), do: {:error, :empty_package}
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
      Keyword.merge([queueID: @queue_id], opts)

    @base_url
    |> URI.parse()
    |> Map.put(:query, URI.encode_query(opts))
    |> URI.to_string()
  end

  def headers() do
    [
      {"User-Agent", Application.get_env(:ex_esi, :user_agent)}
    ]
  end
end
