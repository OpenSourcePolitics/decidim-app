FROM ruby:2.6.3

ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8
ENV RAILS_ENV=production
ENV RAILS_LOG_TO_STDOUT=true
ENV PORT=3000
ENV SECRET_KEY_BASE=f97271c0788641d98a8a7feaa2b8b40fdc28f83285a4f23703abdaf3ac0641a4f047788fd15e4b698e026325ebda371573c370fd6a3bdb720d7e04a580b84882
ENV RAILS_SERVE_STATIC_FILES=true

ENV BUNDLE_PATH /usr/local/bundle
ENV GEM_PATH /usr/local/bundle
ENV GEM_HOME /usr/local/bundle

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
RUN gem update --system
RUN gem install bundler
RUN bundle check || bundle install --jobs 4
COPY . /app/
EXPOSE 3000
