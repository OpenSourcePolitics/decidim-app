# frozen_string_literal: true

require "decidim/rspec_runner"
require "decidim/assets_hash"

namespace :test do
  desc "Setup tests environment"
  task setup: :environment do
    # :nocov:
    system("rake parallel:drop parallel:create parallel:migrate assets:precompile RAILS_ENV=test")
    # :nocov:
  end

  task :run, [:pattern, :mask, :slice] => :environment do |_, args|
    # :nocov:
    Decidim::RSpecRunner.for(args[:pattern], args[:mask], args[:slice])
    # :nocov:
  end

  task run_all: :environment do
    # :nocov:
    Rake::Task["test:run"].invoke("include", "spec/**/*_spec.rb", "0-1")
    # :nocov:
  end

  task assets_hash: :environment do
    # :nocov:
    print Decidim::AssetsHash.run
    # :nocov:
  end
end
