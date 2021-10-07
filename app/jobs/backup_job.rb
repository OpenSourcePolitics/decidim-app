# frozen_string_literal: true

require "rake"

class BackupJob < ApplicationJob
  def perform(args)
    Rails.application.load_tasks
    Rake::Task[args[:task]].reenable
    Rake::Task[args[:task]].invoke(args[:args])
  end
end