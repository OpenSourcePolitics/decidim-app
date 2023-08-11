# frozen_string_literal: true

require "spec_helper"

describe "rake decidim:repair:url_in_content", type: :task do
  let(:task) { Rake::Task[:"decidim:repair:url_in_content"] }
  let(:deprecated_objectstore_s3_host) { "https://s3.example.org" }

  before do
    clear_enqueued_jobs
    clear_performed_jobs
  end

  after do
    clear_enqueued_jobs
    clear_performed_jobs
  end

  it "preloads the Rails environment" do
    expect(task.prerequisites).to include "environment"
  end

  it "calls the service" do
    with_modified_env DEPRECATED_OBJECTSTORE_S3_HOST: deprecated_objectstore_s3_host do
      expect(Decidim::RepairUrlInContentService).to receive(:run).with(deprecated_objectstore_s3_host, any_args).and_return(true)

      task.execute
    end
  end

  context "when env variable is not set" do
    ["", nil].each do |value|
      it "raises an error" do
        with_modified_env DEPRECATED_OBJECTSTORE_S3_HOST: value do
          expect { task.execute }.to raise_error(ArgumentError)
        end
      end
    end
  end
end
