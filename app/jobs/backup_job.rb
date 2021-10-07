# frozen_string_literal: true

require "rake"

class BackupJob < ApplicationJob
  unique :until_and_while_executing, runtime_lock_ttl: 10.minutes, on_runtime_conflict: :log

  def perform
    BackupService.run
  end
end