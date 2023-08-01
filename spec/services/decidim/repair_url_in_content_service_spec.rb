# frozen_string_literal: true

require "spec_helper"

describe Decidim::RepairUrlInContentService do
  subject { described_class.run(endpoint) }

  let(:endpoint) { "s3.decidim.org" }
  let(:connection_tables) { %w(schema_migrations decidim_comments_comments decidim_proposals_proposals ar_internal_metadata) }

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

    it "only returns Decidim objects as String" do
      expect(subject.models).to eq(["Decidim::Comments::Comment", "Decidim::Proposals::Proposal"])
    end
  end

  describe "#records_for" do
    subject { described_class.new(endpoint).records_for(model) }

    let(:model) { "Decidim::Comments::Comment" }
    let(:comment_1) { create(:comment, body: invalid_body_comment) }
    let(:comment_2) { create(:comment) }
    let(:invalid_body_comment) { { en: "Here is a not valid comment https://#{endpoint}/example" } }

    it "returns all records that have a column of type string jsonb or text" do
      expect(subject).to include(comment_1)
      expect(subject).not_to include(comment_2)
    end
  end
end
