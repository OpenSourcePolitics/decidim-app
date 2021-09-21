# frozen_string_literal: true

namespace :decidim do
  namespace :backup do
    desc "Backup Database"
    task db: :environment do
      init

      Rails.logger.debug Rails.env
      Rails.logger.debug Rails.configuration.database_configuration[Rails.env]

      dbconf = Rails.configuration.database_configuration[Rails.env]

      ActiveRecord::Base.establish_connection
      ActiveRecord::Base.connection
      Rails.logger.debug "after ActiveRecord::Base.connection"
      if ActiveRecord::Base.connected? 
        cmd = "pg_dump -Fc"
        cmd += " -h '#{dbconf[:host]}'" if dbconf[:host].present?
        cmd += " -p '#{dbconf[:port]}'" if dbconf[:port].present?
        cmd += " -u '#{dbconf[:user]}'" if dbconf[:user].present?
        cmd = "PGPASSWORD=#{dbconf[:password]} #{cmd}" if dbconf[:password].present?
        cmd += " -u '#{dbconf[:user]}'" if dbconf[:user].present?
        cmd += " -f '#{task.application.original_dir}/tmp/decidim-backup-db.dump'"
        system cmd
      else
        Rails.logger.error "Cannot connect to DB with configuration"
        Rails.logger.error dbconf.except(:password)
        Rails.logger.error "a password was #{dbconf[:password].present? ? "present" : "missing"}"
      end

      finish
    end

    def init
      Rails.logger = Logger.new($stdout)
    end

    def finish
      Rails.logger.close
    end
  end
end
