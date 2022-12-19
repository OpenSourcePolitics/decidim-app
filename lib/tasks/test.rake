# frozen_string_literal: true

require "decidim/rspec_runner"
require "decidim/assets_hash"

namespace :test do
  desc "Setup tests environment"
  task setup: :environment do
    system("rake parallel:drop parallel:create parallel:migrate assets:precompile RAILS_ENV=test")
  end

  task :run, [:pattern, :mask, :slice] => :environment do |_, args|
    Decidim::RSpecRunner.for(args[:pattern], args[:mask], args[:slice])
  end

  task run_all: :environment do
    Rake::Task["test:run"].invoke("include", "spec/**/*_spec.rb", "0-1")
  end

  task assets_hash: :environment do
    print Decidim::AssetsHash.run
  end
end
