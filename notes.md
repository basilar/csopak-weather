===============
# TODO: Backlog
- rename application to windguru_provider
- logging (at start of functions) to be driven via "reflection"
- generalised environment variables (module name + postfix to define name of env. variable)
- generalised weather stations that are driven by the same engine (e.g. all stations on met.hu)
- in-memory caching of last check rather than DB lookup
- manage weather stations independently, if Csopak does not parse properly, let the others through

==========================================================================================
# encrypt script to prepare local development environment (look up passwd in keypass file)
gpg -c --batch --yes --passphrase ...enter-passphrase-here... setup-windguru.sh
# encrypt fly.io secrets (look up passwd in keypass file)
gpg -c --batch --yes --passphrase ...enter-passphrase-here... notes-for-fly.io-setup.md

==========================================
# locally initialise variable for windguru
. <(gpg -qd setup-windguru.sh.gpg)

===============
# recompile all
mix deps.clean --all
mix deps.get
mix compile

======================================================================================
# creating the DB using mise on the development machine from scratch (PostgreSQL 16.4)
export HOMEBREW_PREFIX=/usr/local/Cellar/
export PKG_CONFIG_PATH=/usr/local/Cellar/icu4c/74.2/lib/pkgconfig/
brew install gcc readline zlib curl ossp-uuid icu4c pkg-config
mise use postgres@16.4

alias mise-start-postgresql="PGPORT=5433 pg_ctl start"
alias mise-stop-postgresql="pg_ctl stop"

psql -U postgres -p 5433 -c "CREATE USER csopakweather WITH PASSWORD 'csopakweather';"
psql -U postgres -p 5433 -c "CREATE DATABASE csopakweather OWNER csopakweather;"

==============================
# Setting DB on my dev machine
export CSOPAK_WEATHER_DB=csopakweather
export CSOPAK_WEATHER_DB_USER=csopakweather
export CSOPAK_WEATHER_DB_PASSWORD=csopakweather
export CSOPAK_WEATHER_DB_HOSTNAME=localhost
export CSOPAK_WEATHER_DB_PORT=5433

mix ecto.create
mix ecto.migrate

psql -U csopakweather -p 5433
csopakweather=> \dt
 public | observation       | table | csopakweather
 public | schema_migrations | table | csopakweather

======================================
# to unit test (from the project root)
export CSOPAK_WEATHER_DB=csopakweather
export CSOPAK_WEATHER_DB_USER=csopakweather
export CSOPAK_WEATHER_DB_PASSWORD=csopakweather
export CSOPAK_WEATHER_DB_HOSTNAME=localhost
export CSOPAK_WEATHER_DB_PORT=5433

export TEST_HTTP_RESPONSE_TYPE=success
mix test test/collector_test.exs

============================================
# to run the project (from the project root)
export CSOPAK_WEATHER_DB=csopakweather
export CSOPAK_WEATHER_DB_USER=csopakweather
export CSOPAK_WEATHER_DB_PASSWORD=csopakweather
export CSOPAK_WEATHER_DB_HOSTNAME=localhost
export CSOPAK_WEATHER_DB_PORT=5433

# set secret variables
. <(gpg -qd setup-windguru.sh.gpg)
iex -S mix

=================
# fly.io Redeploy
> fly deploy

==============
# Docker build
- in docker desktop change this (otherwise you get failed to solve
  with frontend dockerfile.v0: failed to create LLB definition: pull
  access denied, repository does not exist or may require authorization:
  server message: insufficient_scope: authorization failed)
  → "buildkit": false
- docker image build -t elixir/csopak-weather .
