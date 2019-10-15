FROM ruby:2.6.3

ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8
ENV RAILS_ENV=production
ENV RAILS_LOG_TO_STDOUT=true
ENV PORT=3000
ENV SECRET_KEY_BASE=f97271c0788641d98a8a7feaa2b8b40fdc28f83285a4f23703abdaf3ac0641a4f047788fd15e4b698e026325ebda371573c370fd6a3bdb720d7e04a580b84882
ENV RAILS_SERVE_STATIC_FILES=true

# Installs bundler dependencies
ENV \
  BUNDLE_BIN=/usr/local/bundle/bin \
  BUNDLE_JOBS=10 \
  BUNDLE_PATH=/usr/local/bundle \
  BUNDLE_RETRY=3 \
  GEM_HOME=/bundle
ENV PATH="${BUNDLE_BIN}:${PATH}"

RUN apt-get update -qq
RUN apt-get install -y git imagemagick wget \
    && apt-get clean
RUN curl -sL https://deb.nodesource.com/setup_10.x | bash - \
    && apt-get install -y nodejs \
    && apt-get clean
RUN npm install -g npm@6.3.0

WORKDIR /app
RUN mkdir -p /app

COPY docker-entrypoint.sh /app/
RUN chmod +x /app/docker-entrypoint.sh

COPY Gemfile* /app/
RUN export BUNDLER_VERSION=$(cat Gemfile.lock | tail -1 | tr -d " ")
RUN gem install bundler
RUN bundle check || bundle install --system
COPY . /app/
EXPOSE 3000
