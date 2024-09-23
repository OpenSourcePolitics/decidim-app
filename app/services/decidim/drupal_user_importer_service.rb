# frozen_string_literal: true

require "logger_with_stdout"

module Decidim
  class DrupalUserImporterService
    COLUMNS = %w(
      uid
      name
      mail
      status
      created
      access
      login
    ).freeze

    EMAIL_REGEX_PATTERN = /^[A-Za-z0-9+_.-]+@[A-Za-z0-9.-]+$/

    def self.run(**args)
      new(**args).execute
    end

    def initialize(**args)
      @logger = ::LoggerWithStdout.new("log/import-bdx-users--#{Time.zone.now.strftime("%Y-%m-%d-%H-%M-%S")}.log")
      @logger.warn "Rake(import:bdx:users)> initializing..."
      @organization = args[:organization]
      @limit = args[:limit]
      @errors = []
      @existing = 0
      @created = 0
      @anonymous = 0
      @dev = true
    end

    def execute
      @logger.warn "Rake(import:bdx:users)> executing..."
      rows = select_users_from_external_db.as_json

      if rows.blank?
        @logger.warn "Rake(import:bdx:users)> No rows found"
        return
      else
        @logger.warn "Rake(import:bdx:users)> found #{rows.size} rows"
      end

      rows.each do |row|

        # fix name with "@"" and "."
        row["fixed-name"] = row["name"].gsub(/@/,"-a-").gsub(/\./,"--")

        if existing_user?(row)
          update_existing_user!(row)
        elsif valid_email?(row["mail"])
          create_user!(row)
        else
          create_anonymous_user!(row)
        end

      rescue ActiveRecord::RecordInvalid => e
        case e.message
        when /Validation failed: Password is too similar to your email/, /La validation a échoué : Mot de passe est trop similaire à votre email/
          @logger.warn { "Rake(import:bdx:users)>  #{e.class}: '#{e.message}' => #{row["mail"]}" }
          create_anonymous_user!(row)
        when /Validation failed: Nickname is invalid/, /La validation a échoué : Pseudonyme n'est pas valide/, /La validation a échoué : Nickname n'est pas valide/
          @logger.warn { "Rake(import:bdx:users)>  #{e.class}: '#{e.message}' => #{nicknamize(row["fixed-name"])}" }
          create_anonymous_user!(row)
        else
          @logger.warn { "Rake(import:bdx:users)>  #{e.class}: '#{e.message}'" }
          @errors.push(row.merge({ error: "#{e.class}: #{e.message}" }))
        end
        next
      rescue StandardError => e
        @logger.warn { "Rake(import:bdx:users)>  #{e.class}: '#{e.message}'" }
        @errors.push(row.merge({ error: "#{e.class}: #{e.message}" }))
        next
      end

      @logger.warn "#{@created} users created"
      @logger.warn "#{@existing} users already existing (updated)"
      @logger.warn "#{@anonymous} anonymous users because of missing data"
      @logger.warn "#{@errors.size} errors"
      write_csv_error_file if @errors.present?
      @logger.warn "Rake(import:bdx:users)> terminated"
    end

    private

    def select_users_from_external_db
      ::Drupal::User.select(COLUMNS).where.not(mail: [nil, ""]).limit(@limit)
    end

    def existing_user?(data)
      Decidim::User.exists?(email: data["mail"]) || Decidim::User.where("extended_data::jsonb @> :drupal", drupal: { drupal: { uid: data["uid"] } }.to_json).present?
    end

    def valid_email?(email)
      ValidEmail2::Address.new(email).valid?
    end

    def create_user!(data)
      Decidim::User.create!(
        name: data["fixed-name"],
        nickname: nicknamize(data["fixed-name"]),
        email: data["mail"],
        organization: @organization,
        password: generated_password = SecureRandom.hex,
        password_confirmation: generated_password,
        newsletter_notifications_at: nil,
        confirmed_at: Time.zone.now, # skip_confirmation!
        tos_agreement: "1",
        extended_data: generate_extended_data(data)
      )
      @created += 1
    end

    def update_existing_user!(data)
      user = Decidim::User.find_by(email: data["mail"]) || Decidim::User.where("extended_data::jsonb @> :drupal", drupal: { drupal: { uid: data["uid"] } }.to_json)&.first
      user.extended_data.merge!(generate_extended_data(data))
      user.save!
      @existing += 1
    end

    def create_anonymous_user!(data)
      extended_data = generate_extended_data(data)
      extended_data[:drupal] = extended_data[:drupal].merge({ status: "anonymized at import" })
      Decidim::User.create!(
        name: "",
        organization: @organization,
        newsletter_notifications_at: nil,
        password: generated_password = SecureRandom.hex,
        password_confirmation: generated_password,
        deleted_at: Time.zone.now,
        tos_agreement: "1",
        extended_data: extended_data
      )
      @anonymous += 1
    end

    def generate_extended_data(data)
      {
        drupal: {
          uid: data["uid"],
          name: data["name"],
          mail: data["mail"],
          uid: data["uid"],
          created: integer_to_datetime(data["created"]),
          access: integer_to_datetime(data["access"]),
          login: integer_to_datetime(data["login"]),
          status: data["status"]
        }
      }
    end

    def integer_to_datetime(value)
      Time.zone.at(value)
    end

    def nicknamize(name)
      Decidim::UserBaseEntity.nicknamize(name&.parameterize&.tableize&.camelize, organization: @organization)[0..-2]
    end

    def write_csv_error_file
      Dir.mkdir("tmp/drupal_import") unless File.exist?("tmp/drupal_import")
      file_path = "tmp/drupal_import/errors--import-bdx-users--#{Time.zone.now.strftime("%Y-%m-%d-%H-%M-%S")}.csv"
      FileUtils.mkdir_p(File.dirname(file_path))
      file_exists = File.exist?(file_path) && !File.zero?(file_path)

      CSV.open(file_path, "a") do |csv|
        csv << @errors.first.keys unless file_exists || @errors.empty?
        @errors.each do |error|
          csv << error.values
        end
      end
    end
  end
end
