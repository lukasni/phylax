defmodule Phylax.Pathfinder.Repo do
  use Ecto.Repo,
    otp_app: :phylax,
    adapter: Ecto.Adapters.MyXQL,
    read_only: true
end
