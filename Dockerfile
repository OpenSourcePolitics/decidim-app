FROM ruby:3.2.2-slim as builder

ARG DOCKER_IMAGE_TAG
ARG DOCKER_IMAGE_NAME
ARG DOCKER_IMAGE
ARG TARGETARCH

ENV RAILS_ENV=production \
    NODE_ENV=production \
    SECRET_KEY_BASE=dummy \
    BUNDLE_JOBS=8 \
    MAKEFLAGS="-j8" \
    NODE_OPTIONS="--max-old-space-size=4096" \
    EXECJS_RUNTIME=Node

WORKDIR /opt/decidim

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    rm -f /var/lib/apt/lists/lock && \
    apt-get update && apt-get install -y --no-install-recommends \
    libpq-dev curl git libicu-dev build-essential wkhtmltopdf xz-utils \
    && NODE_VERSION=22.12.0 \
    && case "${TARGETARCH}" in \
         "amd64")  NODE_ARCH="linux-x64" ;; \
         "arm64")  NODE_ARCH="linux-arm64" ;; \
         *)        echo "Unsupported architecture: ${TARGETARCH}" && exit 1 ;; \
       esac \
    && curl -fsSLO https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-${NODE_ARCH}.tar.xz \
    && tar -xJf node-v${NODE_VERSION}-${NODE_ARCH}.tar.xz -C /usr/local --strip-components=1 \
    && rm node-v${NODE_VERSION}-${NODE_ARCH}.tar.xz \
    && npm install --global yarn \
    && gem install bundler:2.5.22

COPY Gemfile Gemfile.lock ./

RUN --mount=type=cache,target=/usr/local/bundle/cache \
    --mount=type=cache,target=/root/.bundle \
    bundle config set --local without 'development test' && \
    bundle install -j8 --retry 3

COPY . .

RUN --mount=type=cache,target=/opt/decidim/tmp/cache \
    --mount=type=cache,target=/root/.npm \
    --mount=type=cache,target=/root/.cache/yarn \
    --mount=type=cache,target=/opt/decidim/node_modules/.cache \
    bundle exec rake decidim:webpacker:install assets:precompile deface:precompile shakapacker:compile

RUN rm -rf node_modules tmp/cache vendor/bundle/spec .git .gitignore .dockerignore \
    && rm -rf /usr/local/bundle/cache/*.gem \
    && find /usr/local/bundle/gems/ \( -name "*.c" -o -name "*.o" -o -name "*.h" \) -delete \
    && find /usr/local/bundle/bundler/gems/ -type d \( -name "spec" -o -name "test" \) -exec rm -rf {} + 2>/dev/null || true \
    && find /usr/local/bundle/bundler/gems/decidim-* -type d -name "db" -exec sh -c 'rm -rf "$1/migrate"' _ {} \; 2>/dev/null || true \
    && find /usr/local/bundle/bundler/gems/decidim-* -type d -name "docs" -exec rm -rf {} + 2>/dev/null || true \
    && rm -rf log/*.log tmp/* public/packs-test

FROM ruby:3.2.2-slim as runner

ARG DOCKER_IMAGE_TAG
ARG DOCKER_IMAGE_NAME
ARG DOCKER_IMAGE

ENV RAILS_ENV=production \
    NODE_ENV=production \
    SECRET_KEY_BASE=dummy \
    DOCKER_IMAGE_NAME=${DOCKER_IMAGE_NAME:-decidim-app} \
    DOCKER_IMAGE_TAG=${DOCKER_IMAGE_TAG:-latest} \
    DOCKER_IMAGE=${DOCKER_IMAGE:-rg.fr-par.scw.cloud/decidim-app/decidim-app} \
    MALLOC_ARENA_MAX=2 \
    RUBY_YJIT_ENABLE=1 \
    LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libjemalloc.so.2

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    rm -f /var/lib/apt/lists/lock && \
    apt-get update && apt-get install -y --no-install-recommends \
    postgresql-client imagemagick libproj-dev proj-bin p7zip-full wkhtmltopdf libgeos-dev libjemalloc2 \
    && gem install bundler:2.5.22

RUN groupadd --gid 1000 decidim && \
    useradd --uid 1000 --gid decidim --create-home --shell /bin/bash decidim

WORKDIR /opt/decidim

COPY --from=builder --chown=decidim:decidim /usr/local/bundle /usr/local/bundle
COPY --from=builder --chown=decidim:decidim /opt/decidim /opt/decidim

USER decidim

EXPOSE 3000
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]
