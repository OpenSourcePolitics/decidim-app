# frozen_string_literal: true

require "spec_helper"

describe "rake decidim:backup", type: :task do
  before do
    clear_enqueued_jobs
    clear_performed_jobs
    allow(Decidim::BackupService).to receive(:run).and_return(nil)
    allow(Decidim::S3SyncService).to receive(:run).and_return(nil)
    allow(Decidim::S3RetentionService).to receive(:run).and_return(nil)
  end

  after do
    clear_enqueued_jobs
    clear_performed_jobs
  end

  shared_examples_for "rake decidim:backup" do |command|
    context "with rake decidim:backup:#{command}" do
      let(:task) { Rake::Task[:"decidim:backup:#{command}"] }

      it "preloads the Rails environment" do
        expect(task.prerequisites).to include "environment"
      end

      it "performs backup service with scope #{command}" do
        task.reenable
        task.invoke

        expect(Decidim::BackupService).to have_received(:run).with(scope: command.to_sym).once
      end
    end
  end

  it_behaves_like "rake decidim:backup", "db"
  it_behaves_like "rake decidim:backup", "uploads"
  it_behaves_like "rake decidim:backup", "env"
  it_behaves_like "rake decidim:backup", "git"

  context "with rake decidim:backup:all" do
    let(:task) { Rake::Task[:"decidim:backup:all"] }

    it "preloads the Rails environment" do
      expect(task.prerequisites).to include "environment"
    end

    it "performs backup service with s3sync all" do
      task.reenable
      task.invoke

      expect(Decidim::BackupService).to have_received(:run).with(s3sync: false).once
    end
  end

  context "with rake decidim:backup:s3sync" do
    let(:task) { Rake::Task[:"decidim:backup:s3sync"] }

    it "preloads the Rails environment" do
      expect(task.prerequisites).to include "environment"
    end

    it "calls S3SyncService" do
      task.reenable
      task.invoke

      expect(Decidim::S3SyncService).to have_received(:run).once
    end
  end

  context "with rake decidim:backup:s3retention" do
    let(:task) { Rake::Task[:"decidim:backup:s3retention"] }

    it "preloads the Rails environment" do
      expect(task.prerequisites).to include "environment"
    end

    it "calls S3RetentionService" do
      task.reenable
      task.invoke

      expect(Decidim::S3RetentionService).to have_received(:run).once
    end
  end
end
