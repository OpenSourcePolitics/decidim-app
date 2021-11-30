FROM ruby:2.7.1

# Install NodeJS
RUN curl https://deb.nodesource.com/setup_16.x | bash
RUN apt install -y nodejs

# Install Yarn
RUN curl -sL https://dl.yarnpkg.com/debian/pubkey.gpg | gpg --dearmor | tee /usr/share/keyrings/yarnkey.gpg >/dev/null
RUN echo "deb [signed-by=/usr/share/keyrings/yarnkey.gpg] https://dl.yarnpkg.com/debian stable main" | tee /etc/apt/sources.list.d/yarn.list
RUN apt update && apt install -y yarn

# Decidim dependencies
RUN apt install -y libicu-dev postgresql-client

# Install npm
RUN npm install -g npm@6.3.0
# Install bundler
RUN gem install bundler:2.2.29

# Copy all decidim-app content to /app
ADD . /app
WORKDIR /app

RUN bundle install

# Configure endpoint.
COPY ./entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]
EXPOSE 3000

CMD ["rails", "server", "-b", "0.0.0.0"]
