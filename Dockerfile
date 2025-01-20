FROM ruby:3.2.2-slim as builder

ENV RAILS_ENV=production \
    NODE_ENV=production \
    SECRET_KEY_BASE=dummy

WORKDIR /opt/decidim

RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq-dev curl git libicu-dev build-essential openssl ca-certificates \
    && curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && npm install --global yarn \
    && gem install bundler:2.5.22 \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

COPY Gemfile Gemfile.lock ./

RUN bundle install --jobs="$(nproc)" --retry=3

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
    LD_PRELOAD="libjemalloc.so.2" \
    MALLOC_CONF="background_thread:true,metadata_thp:auto,dirty_decay_ms:5000,muzzy_decay_ms:5000,narenas:2"

RUN apt-get update && apt-get install -y --no-install-recommends \
    postgresql-client imagemagick libproj-dev proj-bin libjemalloc2 \
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
