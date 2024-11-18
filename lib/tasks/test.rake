# frozen_string_literal: true

namespace :test do
  desc "Setup tests environment"
  task setup: :environment do
    system("RAILS_ENV=test bundle exec rake db:drop")
    system("RAILS_ENV=test bundle exec rake db:create")
    system("RAILS_ENV=test bundle exec rake db:migrate")
  end
end
