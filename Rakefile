# frozen_string_literal: true

# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.
require_relative "config/application"

# APPEARED WHILE BUMPING TO DECIDIM 0.31
# CRITICAL: Define missing decidim_awesome task BEFORE loading all tasks
# This prevents the upgrade_tasks.rake from failing when it tries to enhance a non-existent task
namespace :decidim_decidim_awesome do
  namespace :install do
    desc "Copy migrations from decidim_decidim_awesome to application"
    task :migrations do
      # This task will be enhanced by decidim_awesome_upgrade_tasks.rake
      # We just need it to exist first
    end
  end
end

Rails.application.load_tasks

unless Rails.env.production?
  require "bundler/audit/task"
  Bundler::Audit::Task.new
end
