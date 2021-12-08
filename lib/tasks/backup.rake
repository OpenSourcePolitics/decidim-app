# frozen_string_literal: true

namespace :decidim do
  namespace :backup do
    desc "Backup Database"
    task db: :environment do
      Decidim::BackupService.run(scope: :db, s3sync: false)
    end

    desc "Backup uploads"
    task uploads: :environment do
      Decidim::BackupService.run(scope: :uploads, s3sync: false)
    end

    desc "Backup env"
    task env: :environment do
      Decidim::BackupService.run(scope: :env, s3sync: false)
    end

    desc "Backup git"
    task git: :environment do
      Decidim::BackupService.run(scope: :git, s3sync: false)
    end

    desc "Backup all"
    task all: :environment do
      Decidim::BackupService.run(s3sync: false)
    end

    desc "Synchronize files with Object Storage"
    task s3sync: :environment do
      Decidim::S3SyncService.run
    end

    desc "Delete old files from Object Storage with a retention schedule"
    task s3retention: :environment do
      Decidim::S3RetentionService.run
    end
  end
end
