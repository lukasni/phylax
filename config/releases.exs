# In this file, we load production configuration and secrets
# from environment variables. You can also hardcode secrets,
# although such is generally not recommended and you have to
# remember to add this file to your .gitignore.
import Config

database_url =
  System.get_env("DATABASE_URL") ||
    raise """
    environment variable DATABASE_URL is missing.
    For example: ecto://USER:PASS@HOST/DATABASE
    """

config :phylax, Phylax.Repo,
  # ssl: true,
  url: database_url,
  pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")

pathfinder_database_url =
  System.get_env("PATHFINDER_DATABASE_URL") ||
    raise """
    environment variable PATHFINDER_DATABASE_URL is missing.
    For example: ecto://USER:PASS@HOST/DATABASE
    """

config :phylax, Phylax.Pathfinder.Repo,
  # ssl: true,
  url: database_url,
  pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")

bot_token =
  System.get_env("BOT_TOKEN") ||
    raise """
    environment variable BOT_TOKEN is missing.
    """

config :nostrum,
    token: bot_token

secret_key_base =
  System.get_env("SECRET_KEY_BASE") ||
    raise """
    environment variable SECRET_KEY_BASE is missing.
    You can generate one by calling: mix phx.gen.secret
    """

lv_signing_salt =
  System.get_env("LIVEVIEW_SIGNING_SALT") ||
    raise """
    environment variable LIVEVIEW_SIGNING_SALT is missing.
    You can generate one by calling: mix phx.gen.secret 32
    """

config :phylax, PhylaxWeb.Endpoint,
  http: [
    port: String.to_integer(System.get_env("PORT") || "4000"),
    transport_options: [socket_opts: [:inet6]]
  ],
  secret_key_base: secret_key_base,
  live_view: [signing_salt: lv_signing_salt]

config :ex_esi,
  user_agent:
    "Phylax/0.2.0 (#{Mix.env() |> to_string() |> String.upcase()} #{to_string(node())}) Erlang/OTP #{
      :erlang.system_info(:otp_release)
    } [erts-#{:erlang.system_info(:version)}] catherinesolenne/tweetfleet"

# ## Using releases (Elixir v1.9+)
#
# If you are doing OTP releases, you need to instruct Phoenix
# to start each relevant endpoint:
#
# Not setting this up yet for 0.2.0 since the webinterface is not implemented yet.
#
#     config :phylax, PhylaxWeb.Endpoint, server: true
#
# Then you can assemble a release by calling `mix release`.
# See `mix help release` for more information.
