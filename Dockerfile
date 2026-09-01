ARG ELIXIR_VERSION=1.20.4
ARG ERLANG_VERSION=29.0.6
ARG ALPINE_VERSION=3.22.5

FROM hexpm/elixir:${ELIXIR_VERSION}-erlang-${ERLANG_VERSION}-alpine-${ALPINE_VERSION} AS builder

RUN apk add --no-cache build-base git

WORKDIR /app

RUN mix local.hex --force && mix local.rebar --force

ENV MIX_ENV=prod

COPY mix.exs mix.lock ./
RUN mix deps.get --only $MIX_ENV
RUN mix deps.compile

COPY config config
COPY lib lib
COPY priv priv
COPY assets assets
RUN mix compile
RUN mix assets.deploy
RUN mix release

FROM alpine:${ALPINE_VERSION} AS app

RUN apk add --no-cache libstdc++ openssl ncurses-libs libgcc wget

WORKDIR /app

RUN addgroup -S treby && adduser -S treby -G treby

COPY --from=builder --chown=treby:treby /app/_build/prod/rel/treby ./

USER treby

ENV MIX_ENV=prod
ENV PHX_SERVER=true

EXPOSE 4000

HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
  CMD wget -qO- http://127.0.0.1:4000/health || exit 1

CMD ["bin/treby", "start"]
