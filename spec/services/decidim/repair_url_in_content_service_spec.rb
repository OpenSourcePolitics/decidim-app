# frozen_string_literal: true

require "spec_helper"

describe Decidim::RepairUrlInContentService do
  subject { described_class.run(endpoint) }

  let(:endpoint) { "s3.decidim.org" }
  let(:connection_tables) { ["schema_migrations", "decidim_comments_comments", "decidim_proposals_proposals", "ar_internal_metadata"] }

  context "when endpoint is blank" do
    let(:endpoint) { nil }

    it "returns false" do
      expect(subject).to be_falsey
    end
  end

  describe "#models" do
    subject { described_class.new(endpoint) }

    before do
      allow(ActiveRecord::Base.connection).to receive(:tables).and_return(connection_tables)
    end

    it "only returns Decidim objects" do
      expect(subject.models).to eq([Decidim::Comments::Comment, Decidim::Proposals::Proposal])
    end
  end
end
