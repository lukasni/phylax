defmodule Phylax.Repo do
  use Ecto.Repo,
    otp_app: :phylax,
    adapter: Ecto.Adapters.Postgres
end
