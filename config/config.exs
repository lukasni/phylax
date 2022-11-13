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
  user_agent:
    "Phylax/0.4.4 (#{Mix.env() |> to_string() |> String.upcase()} #{to_string(node())}) Erlang/OTP #{
      :erlang.system_info(:otp_release)
    } [erts-#{:erlang.system_info(:version)}] catherinesolenne/tweetfleet",
  http_client: ExEsi.Request.Finch,
  finch_opts: [name: FinchClient],
  cache: ExEsi.Cache.ETSStore,
  debug_requests: false

config :nosedrum,
  prefix: System.get_env("BOT_PREFIX") || "."

config :nostrum,
  token: System.get_env("BOT_TOKEN"),
  num_shards: :auto,
  caches: %{
    presences: Nostrum.Cache.PresenceCache.NoOp
  },
  gateway_intents: [
    :direct_messages,
    :guild_bans,
    :guild_members,
    :guild_message_reactions,
    :guild_messages,
    :guild_presences,
    :guilds,
    :message_content
  ]

config :phylax, Phylax.Cache.ChainCache, expire_after: :timer.minutes(1)

# Configures the endpoint
config :phylax, PhylaxWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "zeg+i64Il7GJeHePHi3+M61cXCzjX4hPCBIXuY2HWa2VTzwPsIF2oMlTJsHKqSVg",
  render_errors: [view: PhylaxWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Phylax.PubSub,
  live_view: [signing_salt: "OIuI3HzZ"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :phylax, Phylax.Mailer, adapter: Swoosh.Adapters.Local

# Swoosh API client is needed for adapters other than SMTP.
config :swoosh, :api_client, false

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.14.0",
  default: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :tailwind,
  version: "3.0.15",
  default: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
