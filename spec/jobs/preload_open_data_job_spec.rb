# frozen_string_literal: true

require "spec_helper"

describe PreloadOpenDataJob do
  subject { described_class }

  let(:task) { Rake::Task["decidim:metrics:all"] }

  it "doesn't raise an error" do
    expect { subject.perform_now }.not_to raise_error
  end
end
