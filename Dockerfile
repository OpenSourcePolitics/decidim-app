ARG DOCKER_IMAGE_TAG
ARG DOCKER_IMAGE_NAME
ARG DOCKER_IMAGE

FROM ruby:3.2.2-slim as builder

ENV RAILS_ENV=production \
    NODE_ENV=production \
    SECRET_KEY_BASE=dummy

WORKDIR /opt/decidim

RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq-dev curl git libicu-dev build-essential \
    && curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && npm install --global yarn \
    && gem install bundler:2.5.22 \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

COPY Gemfile Gemfile.lock ./

RUN bundle config set --local without 'development test' && \
    bundle install -j"$(nproc)"

COPY . .

RUN bundle exec rake decidim:webpacker:install && \
    bundle exec rake assets:precompile && \
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

ENV RAILS_ENV=production \
    NODE_ENV=production \
    SECRET_KEY_BASE=dummy \
    DOCKER_IMAGE_NAME=${DOCKER_IMAGE_NAME:-decidim-app} \
    DOCKER_IMAGE_TAG=${DOCKER_IMAGE_TAG:-latest} \
    DOCKER_IMAGE=${DOCKER_IMAGE:-rg.fr-par.scw.cloud/decidim-app/decidim-app}


RUN apt-get update && apt-get install -y --no-install-recommends \
    postgresql-client imagemagick libproj-dev proj-bin p7zip-full \
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
