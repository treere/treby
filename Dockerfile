FROM elixir:1.18-alpine AS builder

RUN apk add --no-cache build-base git

WORKDIR /app

RUN mix local.hex --force && \
    mix local.rebar --force

ENV MIX_ENV=dev

COPY mix.exs mix.lock ./
RUN mix deps.get --only $MIX_ENV
RUN mix deps.compile

COPY config config
COPY lib lib
COPY priv priv
COPY assets assets

RUN mix assets.deploy

FROM elixir:1.18-alpine

RUN apk add --no-cache libstdc++ openssl libgcc

WORKDIR /app

RUN mix local.hex --force && \
    mix local.rebar --force

ENV MIX_ENV=dev

COPY --from=builder /app/deps deps
COPY --from=builder /app/_build _build
COPY --from=builder /app/config config
COPY --from=builder /app/lib lib
COPY --from=builder /app/priv priv
COPY --from=builder /app/assets assets
COPY --from=builder /app/mix.exs mix.lock .

EXPOSE 4000

CMD ["mix", "phx.server"]