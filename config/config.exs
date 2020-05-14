# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :phylax,
  ecto_repos: [Phylax.Repo]

config :ex_esi,
  user_agent: "Phylax/0.1.0 (#{Mix.env() |> to_string() |> String.upcase()} #{to_string(node())}) Erlang/OTP #{:erlang.system_info(:otp_release)} [erts-#{:erlang.system_info(:version)}] catherinesolenne/tweetfleet"

config :nosedrum,
  prefix: System.get_env("BOT_PREFIX") || "."

config :nostrum,
  token: System.get_env("BOT_TOKEN"),
  num_shards: :auto

config :phylax, Phylax.Cache.ChainCache, expire_after: :timer.minutes(1)

# Configures the endpoint
config :phylax, PhylaxWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "zeg+i64Il7GJeHePHi3+M61cXCzjX4hPCBIXuY2HWa2VTzwPsIF2oMlTJsHKqSVg",
  render_errors: [view: PhylaxWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Phylax.PubSub,
  live_view: [signing_salt: "OIuI3HzZ"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
