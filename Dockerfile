FROM ruby:2.7.5-alpine as builder

ENV RAILS_ENV=production \
    SECRET_KEY_BASE=dummy

WORKDIR /app

# Install NodeJS
RUN apk add --no-cache --update nodejs yarn tzdata git icu-dev libpq-dev build-base proj proj-dev postgresql-client && \
    gem install bundler:2.4.9

COPY Gemfile* ./
RUN bundle config set --local without 'development test' && bundle install

COPY package* ./
COPY yarn.lock .
COPY packages packages
RUN yarn install

COPY . .

RUN bundle exec bootsnap precompile --gemfile app/ lib/ config/ bin/ db/ && \
    bundle exec rails assets:precompile && \
    bundle exec rails deface:precompile

RUN rm -rf node_modules tmp/cache vendor/bundle spec

FROM ruby:2.7.5-alpine as runner

ENV RAILS_ENV=production \
    SECRET_KEY_BASE=dummy

RUN apk add --no-cache --update icu-dev tzdata postgresql-client proj proj-dev  && \
    gem install bundler:2.4.9

WORKDIR /app

COPY --from=builder /usr/local/bundle /usr/local/bundle
COPY --from=builder /app /app

EXPOSE 3000
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]
