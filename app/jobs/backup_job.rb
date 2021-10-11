# frozen_string_literal: true

require "rake"

class BackupJob < ApplicationJob
  unique :while_executing, on_conflict: :log

  def perform
    BackupService.run
  end
end
