FROM ruby:3.0.6-slim as builder

ENV RAILS_ENV=production \
    SECRET_KEY_BASE=dummy

WORKDIR /app

RUN apt-get update && \
    apt-get -y install libpq-dev curl git libicu-dev build-essential && \
    curl https://deb.nodesource.com/setup_16.x | bash && \
    apt-get install -y nodejs  && \
    npm install --global yarn && \
    gem install bundler:2.4.9

COPY Gemfile* ./
RUN bundle config set --local without 'development test' && \
    bundle install -j"$(nproc)"

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

FROM ruby:3.0.2-slim as runner

ENV RAILS_ENV=production \
    SECRET_KEY_BASE=dummy \
    RAILS_LOG_TO_STDOUT=true

RUN apt update && \
    apt install -y postgresql-client imagemagick libproj-dev proj-bin libjemalloc2 && \
    gem install bundler:2.4.9

WORKDIR /app

COPY --from=builder /usr/local/bundle /usr/local/bundle
COPY --from=builder /app /app

ENV LD_PRELOAD="libjemalloc.so.2" \
    MALLOC_CONF="background_thread:true,metadata_thp:auto,dirty_decay_ms:5000,muzzy_decay_ms:5000,narenas:2"

EXPOSE 3000
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]
