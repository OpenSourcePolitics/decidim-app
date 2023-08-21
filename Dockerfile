FROM rg.fr-par.scw.cloud/decidim-app-base/decidim-app-base:2.7.5-alpine-jemalloc as builder

ENV RAILS_ENV=production \
    SECRET_KEY_BASE=dummy

WORKDIR /app

# TODO: Use repository version of jemalloc when available
RUN apk add --no-cache --update nodejs yarn tzdata git icu-dev libpq-dev build-base proj proj-dev postgresql-client imagemagick && \
    gem install bundler:2.4.9

COPY Gemfile* ./
RUN bundle config set --local without 'development test' && bundle install

COPY package* ./
COPY yarn.lock .
COPY packages packages
RUN yarn install --frozen-lockfile

COPY . .

RUN bundle exec bootsnap precompile --gemfile app/ lib/ config/ bin/ db/ && \
    bundle exec rails assets:precompile && \
    bundle exec rails deface:precompile

RUN rm -rf node_modules tmp/cache vendor/bundle spec \
    && rm -rf /usr/local/bundle/cache/*.gem \
    && find /usr/local/bundle/gems/ -name "*.c" -delete \
    && find /usr/local/bundle/gems/ -name "*.o" -delete \
    && find /usr/local/bundle/gems/ -type d -name "spec" -prune -exec rm -rf {} \; \
    && rm -rf log/*.log

FROM ruby:2.7.5-alpine as runner

ENV RAILS_ENV=production \
    SECRET_KEY_BASE=dummy \
    RAILS_LOG_TO_STDOUT=true

RUN apk add --no-cache --update icu-dev tzdata postgresql-client proj proj-dev imagemagick  && \
    gem install bundler:2.4.9

WORKDIR /app

COPY --from=builder /usr/local/lib/libjemalloc.so.2 /usr/local/lib/
COPY --from=builder /usr/local/bundle /usr/local/bundle
COPY --from=builder /app /app

ENV LD_PRELOAD=/usr/local/lib/libjemalloc.so.2 \
    MALLOC_CONF="background_thread:true,metadata_thp:auto,dirty_decay_ms:5000,muzzy_decay_ms:5000,narenas:2"

EXPOSE 3000
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]
