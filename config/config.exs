# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :phylax,
  ecto_repos: [Phylax.Repo]

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
