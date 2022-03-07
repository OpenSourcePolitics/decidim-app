# frozen_string_literal: true

namespace :test do
  desc "Setup tests environment"
  task setup: :environment do
    system("rake db:drop RAILS_ENV=test")
    system("rake db:create RAILS_ENV=test")
    system("rake db:migrate RAILS_ENV=test")
    system("rake assets:precompile RAILS_ENV=test")
  end
end
