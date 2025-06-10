# syntax=docker/dockerfile:1

ARG RUBY_VERSION=3.4.2
FROM docker.io/library/ruby:$RUBY_VERSION-slim AS base

WORKDIR /rails

# Base stage - install runtime dependencies only
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      curl \
      libjemalloc2 \
      libvips \
      wkhtmltopdf \
      libpq5 \
      postgresql-client && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development" \
    RAILS_SERVE_STATIC_FILES="true"

# Build stage - full toolchain
FROM base AS build

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      build-essential \
      libpq-dev \
      libyaml-dev \
      pkg-config && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

# Install gems
COPY Gemfile Gemfile.lock ./
RUN gem install bundler:2.6.8 && \
    bundle _2.6.8_ install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git

# App code
COPY . .

# Precompile application code and assets
RUN bundle exec bootsnap precompile app/ lib/ && \
    SECRET_KEY_BASE_DUMMY=1 RAILS_ENV=production bundle exec rails assets:precompile

# Runtime stage
FROM base

COPY --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --from=build /rails /rails

RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash && \
    chown -R rails:rails db log storage tmp

USER rails:rails

HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:80/up || exit 1

ENTRYPOINT ["/rails/bin/docker-entrypoint"]
EXPOSE 80
CMD ["./bin/thrust", "./bin/rails", "server"]
