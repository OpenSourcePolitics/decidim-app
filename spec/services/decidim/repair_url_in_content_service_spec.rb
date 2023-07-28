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

    it "only returns Decidim objects" do
      expect(subject.models).to eq([Decidim::Comments::Comment, Decidim::Proposals::Proposal])
    end
  end

  describe "#schema" do
    subject { described_class.new(endpoint) }

    let(:table_models) { [Decidim::Comments::Comment, Decidim::Proposals::Proposal, Decidim::Organization, Decidim::Authorization] }

    before do
      allow(subject).to receive(:models).and_return(table_models)
    end

    it "returns a Hash as models => Array of PostgreSQL::Column" do
      expect(subject.schema).to be_a Hash
      expect(subject.schema.values.first).to be_a(Array)
      expect(subject.schema.values.first.first).to be_a(ActiveRecord::ConnectionAdapters::PostgreSQL::Column)
    end

    context "when table_models contains Decidim::Proposal" do
      let(:table_models) { [Decidim::Proposals::Proposal] }

      it "values contains columns with type string, jsonb and text" do
        expect(subject.schema.values.first.map(&:type).uniq).to match([:string, :jsonb, :text])
      end
    end
  end
end
