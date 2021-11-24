# frozen_string_literal: true

namespace :test do
  desc "Setup tests environment"
  task setup: :environment do
    system("rake db:drop RAILS_ENV=test")
    system("rake db:create RAILS_ENV=test")
    system("rake db:migrate RAILS_ENV=test")
  end

  desc "Split test for CI testing rake test:split\\[CHUNK_NUMBER\\]"
  task :split, [:chunk] => [:environment] do |_task, args|
    chunk = args[:chunk].to_i
    files_array = Dir.glob(File.join(Rails.root.join("spec"), "**/*_spec.rb"))
    tests_array = Dir.glob(File.join(Rails.root.join(".github"), "**/tests*.yml"))
    raise "Chunk index must be inferior or equal to number of tests workflow" unless chunk <= tests_array.count

    print files_array.in_groups(tests_array.count, false)[chunk - 1].join(" ")
  end
end
