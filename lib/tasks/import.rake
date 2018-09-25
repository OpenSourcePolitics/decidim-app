# frozen_string_literal: true

require 'ruby-progressbar'

namespace :import do
  desc 'Usage: rake import:user FILE=\'<filename.csv>\' ORG=<organization_id> ADMIN=<admin_id> PROCESS=<process_id>'
  task user: :environment do
    display_help unless ENV['FILE'] && ENV['ORG'] && ENV['ADMIN'] && ENV['PROCESS']
    file = ENV['FILE']
    @org = ENV['ORG'].to_i
    @admin = ENV['ADMIN'].to_i
    @process = ENV['PROCESS'].to_i

    if File.extname(file) != '.csv'
      puts 'You must pass a CSV file'
      exit 1
    end

    if @org.class != Integer
      puts 'You must pass an organization id as an integer'
      exit 1
    end

    if @process.class != Integer
      puts 'You must pass a process id as an integer'
      exit 1
    end

    if @admin.class != Integer
      puts 'You must pass an admin id as an integer'
      exit 1
    end

    progressbar = ProgressBar.create(title: 'Importing User', total: CSV.read(file).count, format: '%t%e%B%p%%')
    CSV.open(file, 'r', col_sep: ';') do |row|
      row.map do |id, first_name, last_name, email|
        progressbar.increment
        import_data(id, first_name, last_name, email)
      end
    end
  end
end

def display_help
  puts <<~HEREDOC
    Help:
    Usage: rake import:user FILE='<filename.csv>' ORG=<organization_id>
  HEREDOC
  exit 0
end

def import_data(_id, first_name, last_name, email)
  if email.nil?
    # import_without_email(id, first_name, last_name)
  else
    import_with_email(first_name, last_name, email)
  end
end

def import_without_email(_id, _first_name, _last_name)
  form = Decidim::Admin::ImpersonateUserForm.new(
      name: '',
      reason: '',
      user: '',

      authorization: '',
      handler_name: ''
  )
  Decidim::Admin::ImpersonateUser.call(form)
end

def import_with_email(first_name, last_name, email)
  name = first_name + ' ' + last_name
  form = Decidim::Admin::ParticipatorySpacePrivateUserForm.new
  form.name = name
  form.email = email
  Decidim::Admin::CreateParticipatorySpacePrivateUser.call(
      form,
      fetch_admin,
      fetch_process
  )
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
