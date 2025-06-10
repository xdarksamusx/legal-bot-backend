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
      git \
      libpq-dev \
      libyaml-dev \
      pkg-config \
      nodejs \
      yarn && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

# Install gems and JS dependencies
COPY Gemfile Gemfile.lock ./
RUN gem install bundler:2.6.8 && \
    bundle _2.6.8_ install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git
COPY package.json yarn.lock ./
RUN yarn install --check-files

# Precompile assets and bootsnap
COPY . .
RUN SECRET_KEY_BASE_DUMMY=1 bundle exec rails assets:precompile && \
    bundle exec bootsnap precompile app/ lib/

# Runtime stage
FROM base

COPY --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --from=build /rails /rails

RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash && \
    chown -R rails:rails db log storage tmp

USER rails:rails

# Start server
CMD ["./bin/thrust", "./bin/rails", "server", "-b", "0.0.0.0", "-p", 80]

# Fixed HEALTHCHECK
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 CMD curl -f http://localhost:80/up || exit 1

ENTRYPOINT ["/rails/bin/docker-entrypoint"]
EXPOSE 80