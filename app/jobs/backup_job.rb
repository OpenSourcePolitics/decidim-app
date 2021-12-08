# frozen_string_literal: true

class BackupJob < ApplicationJob
  unique :while_executing, on_conflict: :log

  def perform
    Decidim::BackupService.run(keep_local_files: false) if backup_enabled?
  end

  def backup_enabled?
    Rails.application.config.backup[:enabled]
  end
end
