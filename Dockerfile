ARG MIX_ENV="prod"

# build stage (get image name from https://hub.docker.com/r/hexpm/elixir/tags?page=1&name=1.13.4-erlang-24)
FROM hexpm/elixir:1.13.4-erlang-24.3.4-alpine-3.14.5 AS build

# install build dependencies
RUN apk add --no-cache build-base git python3 curl

# sets work dir
WORKDIR /app

# install hex + rebar
RUN mix local.hex --force && \ 
    mix local.rebar --force
 
ARG MIX_ENV
ENV MIX_ENV="${MIX_ENV}"

# install mix dependencies
COPY mix.exs mix.lock ./
RUN mix deps.get --only $MIX_ENV 

# copy compile configuration files
RUN mkdir config
COPY config/config.exs config/

# compile dependencies
RUN mix deps.compile

# copy assets
COPY priv priv 
# COPY assets assets

# Compile assets
# RUN mix assets.deploy

# compile project
COPY lib lib 
RUN mix compile

# copy runtime configuration file
COPY rel rel
COPY config/runtime.exs config/

# assemble release
RUN mix release

# assemble release
RUN mix release

# app stage
FROM alpine:3.14.5 AS app

ARG MIX_ENV

# install runtime dependencies
RUN apk add --no-cache libstdc++ openssl ncurses-libs

ENV USER="elixir"

WORKDIR "/home/${USER}/app"

# Create  unprivileged user to run the release
RUN addgroup -g 1000 -S "${USER}"
RUN adduser -s /bin/sh -u 1000 -G "${USER}" -h "/home/${USER}" -D "${USER}"
RUN su "${USER}"

# run as user
USER "${USER}"

# copy release executables
COPY --from=build --chown="${USER}":"${USER}" /app/_build/"${MIX_ENV}"/rel/csopak_weather ./

ENTRYPOINT ["bin/csopak_weather"]

CMD ["start"]
 