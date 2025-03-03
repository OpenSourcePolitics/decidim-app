# frozen_string_literal: true

namespace :test do
  desc "Setup tests environment"
  task setup: :environment do
    system("RAILS_ENV=test bundle exec rake db:drop db:create db:migrate")
    system("RAILS_ENV=test bundle exec rails shakapacker:compile")
  end
end

desc "Setup tests environment"
task test_app: :environment do
  system("RAILS_ENV=test bundle exec rake db:drop db:create db:migrate")
  system("RAILS_ENV=test bundle exec rails shakapacker:compile")
end
