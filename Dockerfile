# 1. Base Elixir image with build tools
FROM elixir:1.16-alpine AS build

# Install build dependencies
RUN apk add --no-cache build-base git

# Set environment vars for Elixir and mix
ENV MIX_ENV=prod \
    LANG=C.UTF-8

# Create app directory
WORKDIR /app

# Install Hex + Rebar (build tools for Elixir)
RUN mix local.hex --force && \
    mix local.rebar --force

# Copy mix files and install deps
COPY mix.exs mix.lock ./
RUN mix deps.get --only prod

# Copy source files
COPY config config
COPY lib lib

# Compile the project
RUN mix release

# 2. Release image
FROM alpine:3.18 AS app

RUN apk add --no-cache libstdc++ openssl ncurses

WORKDIR /app

# Copy built app from the previous stage
COPY --from=build /app/_build/prod/rel/demo_rest_app ./

# Set PORT for runtime (optional)
ENV PORT=4000

# Default command
CMD ["bin/demo_rest_app", "start"]
