# frozen_string_literal: true

require "spec_helper"

describe "rake decidim:set_decrypted_private_body", type: :task do
  let(:task) { Rake::Task["decidim:set_decrypted_private_body"] }
  let!(:extra_fields) { create(:awesome_proposal_extra_fields, proposal: create(:extended_proposal)) }

  before do
    extra_fields.private_body = { "en" => '<xml><dl><dt name="something">Something</dt></dl></xml>' }
    extra_fields.save!
  end

  it "preloads the Rails environment" do
    expect(task.prerequisites).to include "environment"
  end

  context "when the environment is development" do
    before do
      allow(Rails.env).to receive(:development?).and_return(true)
    end

    it "executes the job immediately" do
      expect(PrivateBodyDecryptJob).to receive(:perform_now)
      task.execute
    end
  end

  context "when the environment is not development" do
    before do
      allow(Rails.env).to receive(:development?).and_return(false)
    end

    it "enqueues the job to perform later" do
      expect(PrivateBodyDecryptJob).to receive(:perform_later)
      task.execute
    end
  end
end
