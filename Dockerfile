FROM ruby:3.2.2-slim as builder

ARG DOCKER_IMAGE_TAG
ARG DOCKER_IMAGE_NAME
ARG DOCKER_IMAGE
ARG TARGET_ARCH

ENV RAILS_ENV=production \
    NODE_ENV=production \
    SECRET_KEY_BASE=dummy

WORKDIR /opt/decidim

RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq-dev curl git libicu-dev build-essential wkhtmltopdf xz-utils \
    && NODE_VERSION=22.12.0 \
    && case "${TARGET_ARCH}" in \
         "amd64")  NODE_ARCH="linux-x64" ;; \
         "arm64")  NODE_ARCH="linux-arm64" ;; \
         *)        echo "Unsupported architecture: ${TARGET_ARCH}" && exit 1 ;; \
       esac \
    && echo "Downloading Node.js ${NODE_VERSION} for ${NODE_ARCH}..." \
    && curl -fsSLO https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-${NODE_ARCH}.tar.xz \
    && tar -xJf node-v${NODE_VERSION}-${NODE_ARCH}.tar.xz -C /usr/local --strip-components=1 \
    && rm node-v${NODE_VERSION}-${NODE_ARCH}.tar.xz \
    && npm install --global yarn \
    && gem install bundler:2.5.22 \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

COPY Gemfile Gemfile.lock ./

RUN bundle config set --local without 'development test' && \
    bundle install -j"$(nproc)"

COPY . .

RUN bundle exec rake decidim:webpacker:install && \
    bundle exec rake assets:precompile && \
    bundle exec rails deface:precompile && \
    bundle exec rails shakapacker:compile

RUN rm -rf node_modules tmp/cache vendor/bundle/spec \
    && rm -rf /usr/local/bundle/cache/*.gem \
    && find /usr/local/bundle/gems/ -name "*.c" -delete \
    && find /usr/local/bundle/gems/ -name "*.o" -delete \
    && find /usr/local/bundle/bundler/gems/ -type d -name "spec" -prune -exec rm -rf {} \; \
    && find /usr/local/bundle/bundler/gems/decidim-* -type d -name "db/migrate" -prune -exec rm -rf {} \; \
    && find /usr/local/bundle/bundler/gems/decidim-* -type d -name "docs" -prune -exec rm -rf {} \; \
    && rm -rf log/*.log

FROM ruby:3.2.2-slim as runner

ARG DOCKER_IMAGE_TAG
ARG DOCKER_IMAGE_NAME
ARG DOCKER_IMAGE

ENV RAILS_ENV=production \
    NODE_ENV=production \
    SECRET_KEY_BASE=dummy \
    DOCKER_IMAGE_NAME=${DOCKER_IMAGE_NAME:-decidim-app} \
    DOCKER_IMAGE_TAG=${DOCKER_IMAGE_TAG:-latest} \
    DOCKER_IMAGE=${DOCKER_IMAGE:-rg.fr-par.scw.cloud/decidim-app/decidim-app}


RUN apt-get update && apt-get install -y --no-install-recommends \
    postgresql-client imagemagick libproj-dev proj-bin p7zip-full wkhtmltopdf libgeos-dev \
    && gem install bundler:2.5.22 \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN groupadd --gid 1000 decidim && \
    useradd --uid 1000 --gid decidim --create-home --shell /bin/bash decidim

WORKDIR /opt/decidim

COPY --from=builder /usr/local/bundle /usr/local/bundle
COPY --from=builder /opt/decidim /opt/decidim

RUN chown -R decidim:decidim /opt/decidim
USER decidim

EXPOSE 3000
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]
