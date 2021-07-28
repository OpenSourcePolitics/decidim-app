# frozen_string_literal: true

require "ruby-progressbar"

namespace :import do
  desc "Usage: rake import:user FILE='<filename.csv>' ORG=<organization_id> ADMIN=<admin_id> PROCESS=<process_id> [VERBOSE=true]'"
  task user: :environment do
    def validate_input
      validate_file
      validate_process
      validate_admin
      validate_org
    end

    def validate_org
      if @org.class != Integer
        puts "You must pass an organization id as an integer"
        exit 1
      end

      unless current_organization
        puts "Organization does not exist"
        exit 1
      end
    end

    def validate_admin
      if @admin.class != Integer
        puts "You must pass an admin id as an integer"
        exit 1
      end

      unless current_user
        puts "Admin does not exist"
        exit 1
      end
    end

    def validate_process
      if @process.class != Integer
        puts "You must pass a process id as an integer"
        exit 1
      end

      unless current_process
        puts "Process does not exist"
        exit 1
      end
    end

    def validate_file
      unless File.exist?(@file)
        puts "File does not exist, be sure to pass a full path."
        exit 1
      end

      if File.extname(@file) != ".csv"
        puts "You must pass a CSV file"
        exit 1
      end
    end

    def display_help
      puts <<~HEREDOC
        Help:
        Usage: rake import:user FILE='<filename.csv>' ORG=<organization_id> ADMIN=<admin_id> PROCESS=<process_id>
      HEREDOC
      exit 0
    end

    def check_csv(file)
      file.each do |row|
        # Check if id, first_name, last_name are nil
        next unless row[0].nil? || row[1].nil? || row[2].nil?

        puts "Something went wrong, empty field(s) on line #{$INPUT_LINE_NUMBER}"
        puts row.inspect
        exit 1
      end
    end

    def import_data(id, first_name, last_name, email)
      # Extends are only loaded at the last time
      require "extends/commands/decidim/admin/create_participatory_space_private_user_extends"
      require "extends/commands/decidim/admin/impersonate_user_extends"

      if email.nil?
        import_without_email(id, first_name, last_name)
      else
        import_with_email(id, first_name, last_name, email)
      end
    end

    def import_without_email(id, first_name, last_name)
      new_user = Decidim::User.new(
        managed: true,
        name: set_name(first_name, last_name),
        organization: current_organization,
        admin: false,
        roles: [],
        tos_agreement: true
      )
      form = Decidim::Admin::ImpersonateUserForm.from_params(
        user: new_user,
        name: new_user.name,
        reason: "import",
        handler_name: "osp_authorization_handler",
        authorization: Decidim::AuthorizationHandler.handler_for(
          "osp_authorization_handler",
          {
            user: new_user,
            document_number: id
          }
        )
      ).with_context(
        current_organization: current_organization,
        current_user: current_user
      )

      privatable_to = current_process

      Decidim::Admin::ImpersonateUser.call(form) do
        on(:ok) do |user|
          Decidim::ParticipatorySpacePrivateUser.find_or_create_by!(
            user: user,
            privatable_to: privatable_to
          )
          Rails.logger.debug I18n.t("participatory_space_private_users.create.success", scope: "decidim.admin")
          Rails.logger.debug "Registered user with id: #{id}, first_name: #{first_name}, last_name: #{last_name} --> #{user.id}"
        end

        on(:invalid) do
          Rails.logger.debug I18n.t("participatory_space_private_users.create.error", scope: "decidim.admin")
          Rails.logger.debug user.errors.full_messages if user.invalid?
          Rails.logger.debug form.errors.full_messages if form.invalid?
          Rails.logger.debug "Failed to register user with id: #{id}, first_name: #{first_name}, last_name: #{last_name} !!"
          # exit 1
        end
      end
    end

    def import_with_email(id, first_name, last_name, email)
      form = Decidim::Admin::ParticipatorySpacePrivateUserForm.from_params(
        {
          name: set_name(first_name, last_name),
          email: email
        },
        privatable_to: current_process
      )
      Decidim::Admin::CreateParticipatorySpacePrivateUser.call(form, current_user, current_process) do
        on(:ok) do |user|
          Decidim::Authorization.create_or_update_from(
            Decidim::AuthorizationHandler.handler_for(
              "osp_authorization_handler",
              {
                user: user,
                document_number: id
              }
            )
          )
          Rails.logger.debug I18n.t("participatory_space_private_users.create.success", scope: "decidim.admin")
          Rails.logger.debug "Registered user with id: #{id}, first_name: #{first_name}, last_name: #{last_name}, email: #{email} --> #{user.id}"
        end

        on(:invalid) do
          Rails.logger.debug I18n.t("participatory_space_private_users.create.error", scope: "decidim.admin")
          Rails.logger.debug form.errors.full_messages if form.invalid?
          Rails.logger.debug "Failed to register user with id: #{id}, first_name: #{first_name}, last_name: #{last_name}, email: #{email} !!"
          # exit 1
        end
      end
    end

    def set_name(first_name, last_name)
      "#{first_name} #{last_name}"
    end

    def current_user
      @current_user ||= Decidim::User.find(@admin)
    end

    def current_organization
      @current_organization ||= Decidim::Organization.find(@org)
    end

    def current_process
      @current_process ||= Decidim::ParticipatoryProcess.find(@process)
    end

    Rails.application.config.active_job.queue_adapter = :inline

    @verbose = ENV["VERBOSE"].to_s == "true"
    Rails.logger = if @verbose
                     Logger.new($stdout)
                   else
                     Logger.new("log/import-user-#{Time.zone.now.strftime "%Y-%m-%d-%H:%M:%S"}.log")
                   end

    display_help unless ENV["FILE"] && ENV["ORG"] && ENV["ADMIN"] && ENV["PROCESS"]
    @file = ENV["FILE"]
    @org = ENV["ORG"].to_i
    @admin = ENV["ADMIN"].to_i
    @process = ENV["PROCESS"].to_i
    @auth_handler = ENV["AUTH_HANDLER"]

    validate_input

    csv = CSV.read(@file, col_sep: ",", headers: true, skip_blanks: true)
    check_csv(csv)

    count = CSV.read(@file).count

    puts "CSV file is #{count} lines long"

    progressbar = ProgressBar.create(title: "Importing User", total: count, format: "%t%e%B%p%%") unless @verbose

    csv.each do |row|
      progressbar.increment unless @verbose
      # Import user with parsed informations id, first_name, last_name, email
      import_data(row[0], row[1], row[2], row[3])
    end

    Rails.logger.close
  end
end
