FROM ruby:3.0.2

ENV RAILS_ENV=production \
    SECRET_KEY_BASE=dummy

WORKDIR /app

# Install NodeJS
RUN --mount=type=cache,target=/var/cache/apt \
    curl https://deb.nodesource.com/setup_16.x | bash && \
    apt install -y nodejs && \
    apt update && \
    npm install -g npm@8.19.2 && \
    npm install --global yarn && \
    apt install -y libicu-dev postgresql-client && \
    gem install bundler:2.2.17 && \
    rm -rf /var/lib/apt/lists/*

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

# Configure endpoint.
COPY ./entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]
EXPOSE 3000

CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]
