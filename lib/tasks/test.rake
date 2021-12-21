# frozen_string_literal: true

namespace :test do
  desc "Setup tests environment"
  task setup: :environment do
    system("rake db:drop RAILS_ENV=test")
    system("rake db:create RAILS_ENV=test")
    system("rake db:migrate RAILS_ENV=test")
  end

  desc "Split test for CI testing bundle exec rake test:split\\[CHUNK_NUMBER\\]"
  task :split, [:chunk] => [:environment] do |_task, args|
    parallel = ENV.fetch("CI_PARALLEL", 8).to_i
    chunk = args[:chunk].to_i
    files_array = Dir.glob(Rails.root.join("spec/**/*_spec.rb"))
    raise "Chunk index must be inferior or equal to count of test files" unless (chunk <= files_array.count || parallel)

    print files_array.transpose.in_groups(parallel, false)[chunk - 1].join(" ")
  end
end
