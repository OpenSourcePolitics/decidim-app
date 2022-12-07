# frozen_string_literal: true

require "decidim/rspec_runner"
require "decidim/assets_hash"

namespace :test do
  desc "Setup tests environment"
  task setup: :environment do
    system("rake db:drop RAILS_ENV=test")
    system("rake db:create RAILS_ENV=test")
    system("rake db:migrate RAILS_ENV=test")
    system("rake assets:precompile RAILS_ENV=test")
  end

  task :run, [:pattern, :mask, :slice] => :environment do |_, args|
    Decidim::RSpecRunner.for(args[:pattern], args[:mask], args[:slice])
  end

  task :assets_hash => :environment do
    print Decidim::AssetsHash.run
  end
end
