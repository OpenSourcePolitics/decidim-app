# frozen_string_literal: true

class BackupJob < ApplicationJob
  unique :while_executing, on_conflict: :log

  def perform
    Decidim::BackupService.run(keep_local_files: false)
  end
end
