import Config
import Logger
# MIX_ENV=dev iex -S mix

config :csopak_weather, Repo,
  database: System.fetch_env!("CSOPAK_WEATHER_DB"),
  username: System.fetch_env!("CSOPAK_WEATHER_DB_USER"),
  password: System.fetch_env!("CSOPAK_WEATHER_DB_PASSWORD"),
  hostname: System.fetch_env!("CSOPAK_WEATHER_DB_HOSTNAME"),
  port: System.fetch_env!("CSOPAK_WEATHER_DB_PORT")

if config_env() == :prod do
  # production specific configuration
  config :csopak_weather, Repo,
    # ssl: true,
    socket_options: [:inet6],
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")

  # APIs that have Mocks under :test
  config :csopak_weather, :weather_web_api, WeatherWebApi
  config :csopak_weather, :healthcheck_api, WeatherWebApi
end

if config_env() == :dev do
  # APIs that have Mocks under :test
  config :csopak_weather, :weather_web_api, WeatherWebApi
end

if config_env() == :test do
  # Mocks
  config :csopak_weather, :weather_web_api, WeatherWebApiMock
end
