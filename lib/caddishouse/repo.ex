defmodule Caddishouse.Repo do
  use Ecto.Repo,
    otp_app: :caddishouse,
    adapter: Ecto.Adapters.Postgres
end
