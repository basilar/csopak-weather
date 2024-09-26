defmodule Repo do
  use Ecto.Repo,
    otp_app: :csopak_weather,
    adapter: Ecto.Adapters.Postgres
end
