# syntax=docker/dockerfile:1
# check=error=true

ARG RUBY_VERSION=3.4.2
FROM docker.io/library/ruby:$RUBY_VERSION-slim AS base

WORKDIR /rails

# Base stage - install runtime dependencies
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      curl \
      git \                    # <== Add this line
      libjemalloc2 \
      libvips \
      wkhtmltopdf \
      libpq5 \
      libpq-dev \
      postgresql-client && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives


ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development"

# Build stage - contains full build toolchain and dev headers
FROM base AS build

# Install build dependencies (required to compile native gems like pg)
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      libpq-dev \
      postgresql-client \
      build-essential \
      git \
      libyaml-dev \
      pkg-config && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Verify pg_config is available (for debugging purposes)
RUN which pg_config || echo "pg_config not found" && \
    ls -la /usr/bin/pg_config* || echo "no pg_config files found"

# Install gems
COPY Gemfile Gemfile.lock ./
RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
    bundle exec bootsnap precompile --gemfile

# Copy application code
COPY . .

# Precompile bootsnap
RUN bundle exec bootsnap precompile app/ lib/

# Precompile Rails assets
RUN SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile

# Final runtime stage
FROM base

# Copy everything from build
COPY --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --from=build /rails /rails

# Add non-root user
RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash && \
    chown -R rails:rails db log storage tmp
USER 1000:1000

ENTRYPOINT ["/rails/bin/docker-entrypoint"]

EXPOSE 80
CMD ["./bin/thrust", "./bin/rails", "server"]
