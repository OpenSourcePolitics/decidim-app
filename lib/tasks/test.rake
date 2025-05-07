# frozen_string_literal: true

namespace :test do
  desc "Setup tests environment"
  task setup: :environment do
    system("RAILS_ENV=test bundle exec rake db:drop db:create db:migrate")
    system("RAILS_ENV=test bundle exec rails shakapacker:compile")
  end

  task :run, [:pattern, :mask, :slice] => :environment do |_, args|
    # :nocov:
    Decidim::RSpecRunner.for(args[:pattern], args[:mask], args[:slice])
    # :nocov:
  end
end

desc "Setup tests environment"
task test_app: :environment do
  system("RAILS_ENV=test bundle exec rake db:drop db:create db:migrate")
  system("RAILS_ENV=test bundle exec rails shakapacker:compile")
end
