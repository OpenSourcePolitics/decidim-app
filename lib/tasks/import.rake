# frozen_string_literal: true

require 'ruby-progressbar'

namespace :import do
  desc 'Usage: rake import:user FILE=\'<filename.csv>\' ORG=<organization_id> ADMIN=<admin_id> PROCESS=<process_id>\''
  task user: :environment do
    display_help unless ENV['FILE'] && ENV['ORG'] && ENV['ADMIN'] && ENV['PROCESS']
    @file = ENV['FILE']
    @org = ENV['ORG'].to_i
    @admin = ENV['ADMIN'].to_i
    @process = ENV['PROCESS'].to_i
    @auth_handler = ENV['AUTH_HANDLER']

    validate_input

    csv = CSV.read(@file, col_sep: ';')
    check_csv(csv)

    count = CSV.read(@file).count

    puts "CSV file is #{count} lines long"

    @log = File.new("import-user-#{Time.now}.log", "w+")

    progressbar = ProgressBar.create(title: 'Importing User', total: count, format: '%t%e%B%p%%')

    csv.each do |row|
      progressbar.increment
      # Import user with parsed informations id, first_name, last_name, email
      import_data(row[0], row[1], row[2], row[3])
    end
    @log.close
  end
end

private

def validate_input
  validate_file
  validate_process
  validate_admin
  validate_org
end

def validate_org
  if @org.class != Integer
    puts 'You must pass an organization id as an integer'
    exit 1
  end

  unless fetch_organization
    puts 'Organization does not exist'
    exit 1
  end
end

def validate_admin
  if @admin.class != Integer
    puts 'You must pass an admin id as an integer'
    exit 1
  end

  unless fetch_admin
    puts 'Admin does not exist'
    exit 1
  end
end

def validate_process
  if @process.class != Integer
    puts 'You must pass a process id as an integer'
    exit 1
  end

  unless fetch_process
    puts 'Process does not exist'
    exit 1
  end
end

def validate_file
  unless File.exist?(@file)
    puts 'File does not exist, be sure to pass a full path.'
    exit 1
  end

  if File.extname(@file) != '.csv'
    puts 'You must pass a CSV file'
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
    if row[0].nil? || row[1].nil? || row[2].nil?
      puts "Something went wrong, empty field(s) on line #{$.}"
      exit 1
    end
  end
end

def import_data(id, first_name, last_name, email)
  if email.nil?
    import_without_email(id, first_name, last_name)
  else
    import_with_email(first_name, last_name, email)
  end
end

def import_without_email(id, first_name, last_name)
  user = Decidim::User.new(managed: true, admin: false, roles: [])
  name = set_name(first_name, last_name)
  form = Decidim::Admin::ImpersonateUserForm.new
  form.name = name
  form.user = user
  form.handler_name = 'osp_authorization_handler'
  form.authorization = { "document_number": id }
  Decidim::Admin::ImpersonateUser.call(form)
  log_feed("id: #{id}, first_name: #{first_name}, last_name: #{last_name}")
end

def import_with_email(first_name, last_name, email)
  name = set_name(first_name, last_name)
  form = Decidim::Admin::ParticipatorySpacePrivateUserForm.new
  form.name = name
  form.email = email
  Decidim::Admin::CreateParticipatorySpacePrivateUser.call(form, fetch_admin, fetch_process)
  log_feed("first_name: #{first_name}, last_name: #{last_name}, email: #{email}")
end

def set_name(first_name, last_name)
  first_name + ' ' + last_name
end

def fetch_admin
  Decidim::User.find(@admin)
end

def fetch_organization
  Decidim::Organization.find(@org)
end

def fetch_process
  Decidim::ParticipatoryProcess.find(@process)
end

def log_feed(data)
  @log.write("Registered user with #{data}\n")
end
