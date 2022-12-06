# frozen_string_literal: true

require "decidim/rspec_runner"

namespace :test do
  desc "Setup tests environment"
  task setup: :environment do
    system("rake db:drop RAILS_ENV=test")
    system("rake db:create RAILS_ENV=test")
    system("rake db:migrate RAILS_ENV=test")
    system("rake assets:precompile RAILS_ENV=test")
  end

  task :run, [:pattern, :slice] => :environment do |_, args|
    Decidim::RSpecRunner.for(args[:pattern], args[:slice])
  end
end
