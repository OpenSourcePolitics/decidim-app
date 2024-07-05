# frozen_string_literal: true

require "net/http/post/multipart"
require "decidim_app/k8s/configuration_exporter"
require "decidim_app/k8s/organization_exporter"
require "decidim_app/k8s/manager"

namespace :decidim_app do
  desc "Setup Decidim-app"
  task setup: :environment do
    # :nocov:
    puts "Running bundler installation"
    system("bundle install")
    puts "Installing engine migrations..."
    system("bundle exec rake railties:install:migrations")
    puts "Checking for migrations to apply..."
    migrations = `bundle exec rake db:migrate:status | grep down`
    if migrations.present?
      puts "Missing migrations :
#{migrations}"
      puts "Applying missing migrations..."
      system("bundle exec rake db:migrate")
    else
      puts "All migrations are up"
    end

    puts "Setup successfully terminated"
    # :nocov:
  end

  namespace :k8s do
    # This task is used to install your decidim-app to the latest version
    # Meant to be used in a CI/CD pipeline or a k8s job/operator
    # You can add your own customizations here
    desc "Install decidim-app"
    task install: :environment do
      puts "Running db:migrate"
      Rake::Task["db:migrate"].invoke
      Rake::Task["decidim_anonymous_proposals:generate_anonymous_group"].invoke
    end

    # This task is used to upgrade your decidim-app to the latest version
    # Meant to be used in a CI/CD pipeline or a k8s job/operator
    # You can add your own customizations here
    desc "Upgrade decidim-app"
    task upgrade: :environment do
      puts "Running upgrade db:migrate"
      Rake::Task["db:migrate"].invoke
      puts "Running decidim:repair:url_in_content"
      Rake::Task["decidim:repair:url_in_content"].invoke
      puts "Running decidim:repair:translations"
      Rake::Task["decidim:repair:translations"].invoke
      Rake::Task["decidim_anonymous_proposals:generate_anonymous_group"].invoke
    rescue StandardError => e
      puts "Ignoring error: #{e.message}"
      puts "Running decidim:db:migrate"
      Rake::Task["decidim:db:migrate"].invoke
    end

    desc "usage: bundle exec rails k8s:dump_db"
    task dump_db: :environment do
      DecidimApp::K8s::ConfigurationExporter.dump_db
    end

    desc "usage: bundle exec rails k8s:export_configuration IMAGE=<docker_image_ref>"
    task export_configuration: :environment do
      image = ENV.fetch("IMAGE", nil)
      raise "You must specify a docker image, usage: bundle exec rails k8s:export_configuration IMAGE=<image_ref>" if image.blank?

      DecidimApp::K8s::ConfigurationExporter.export!(image)
    end

    desc "Create install or reload install with path='path/to/external_install_configuration.yml'"
    task external_install_or_reload: :environment do
      raise "You must specify a path to an external install configuration, path='path/to/external_install_configuration.yml'" if ENV["path"].blank? || !File.exist?(ENV.fetch(
                                                                                                                                                                      "path", nil
                                                                                                                                                                    ))

      DecidimApp::K8s::Manager.run(ENV.fetch("path", nil))
    end
  end

  namespace :budgets do
    # This task is used to send a reminder by sms to voters who haven't finished their
    # vote for a budget. When you launch the task, you have to pass the id of the budget
    # in a variable in terminal
    desc "send a reminder to vote for budget"
    task send_sms_reminder: :environment do
      if (budget_id = ENV.fetch("BUDGET_ID")).nil?
        p "You need to provide a budget ID"
        next
      end

      if (budget = Decidim::Budgets::Budget.find_by(id: budget_id)).nil?
        p "Budget with id #{budget_id} not found"
        next
      end

      organization = budget.organization

      users_ids = Decidim::Budgets::Order.where(budget: budget)
                                         .pending
                                         &.pluck(:decidim_user_id)
      if users_ids.empty?
        p "no pending votes"
        next
      end
      users = Decidim::User.where(id: users_ids).where.not(phone_number: nil, phone_country: nil)

      if users.blank?
        p "no pending votes from users with phone number"
        next
      end

      filename = "send_sms_reminder_#{Time.current.year}_#{Time.current.month}_#{Time.current.day}_#{Time.current.min}.csv"
      message = I18n.t("decidim.budgets.order_reminder.text_message", locale: organization.default_locale, organization_host: organization.host)

      file = Tempfile.new(filename)
      CSV.open(file, "w", col_sep: ";") do |csv|
        users.each do |user|
          csv << ["#{user.phone_country}#{user.phone_number}", message]
        end
      end
      file.rewind

      p "users ids: #{users.ids}"
      p "csv done at #{filename}"

      api_url = Rails.application.secrets.dig(:decidim, :sms_gateway, :bulk_url)
      username = Rails.application.secrets.dig(:decidim, :sms_gateway, :username)
      password = Rails.application.secrets.dig(:decidim, :sms_gateway, :password)

      url = URI(api_url)
      request = Net::HTTP::Post::Multipart.new(url, {
                                                 u: username,
                                                 p: password,
                                                 f: "sms",
                                                 c: "Reminder",
                                                 file: UploadIO.new(file, "text/csv", filename)
                                               })

      response = Net::HTTP.start(url.hostname, url.port, use_ssl: true) do |https| # pay attention to use_ssl if you need it
        https.request(request)
      end

      p "API response is #{response.body}"
    end
  end
end
