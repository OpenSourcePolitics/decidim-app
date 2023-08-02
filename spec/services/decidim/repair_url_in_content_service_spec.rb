# frozen_string_literal: true

require "spec_helper"

describe Decidim::RepairUrlInContentService do
  subject { described_class.run(deprecated_endpoint) }

  let(:deprecated_endpoint) { "s3.decidim.org" }
  let(:valid_endpoint) { "s3.valid.org" }
  let(:connection_tables) { %w(schema_migrations decidim_comments_comments decidim_proposals_proposals ar_internal_metadata) }
  let(:comment_1) { create(:comment, body: invalid_body_comment) }
  let(:comment_2) { create(:comment) }
  let(:invalid_body_comment) { { en: "Here is a not valid comment with #{deprecated_url}" } }
  let(:deprecated_url) { "https://#{deprecated_endpoint}/xxxx?response-content-disposition=inline%3Bfilename%3D\"BuPa23_reglement-interieur.pdf\"%3Bfilename*%3DUTF-8''BuPa23_r%25C3%25A8glement-int%25C3%25A9rieur.pdf&response-content-type=application%2Fpdf" }

  before do
    allow(ActiveRecord::Base.connection).to receive(:tables).and_return(connection_tables)
    allow_any_instance_of(Decidim::RepairUrlInContentService).to receive(:models).and_return(["Decidim::Comments::Comment", "Decidim::Proposals::Proposal"])
    allow(subject).to receive(:find_service_url_for_blob).with(comment_1.id).and_return("https://#{valid_endpoint}/example")
  end

  it "updates values from comments" do
    expect do
      subject
      comment_1.reload
    end.to change { comment_1.body["en"] }.from(invalid_body_comment[:"en"]).to("Here is a not valid comment https://#{valid_endpoint}/example")
  end

  context "when deprecated_endpoint is blank" do
    let(:deprecated_endpoint) { nil }

    it "returns false" do
      expect(subject).to be_falsey
    end
  end

  describe "#models" do
    subject { described_class.new(deprecated_endpoint) }

    before do
      allow(ActiveRecord::Base.connection).to receive(:tables).and_return(connection_tables)
    end

    it "only returns Decidim objects as String" do
      expect(subject.models).to eq(["Decidim::Comments::Comment", "Decidim::Proposals::Proposal"])
    end
  end

  describe "#records_for" do
    subject { described_class.new(deprecated_endpoint).records_for(model) }

    let(:model) { Decidim::Comments::Comment }

    it "returns all records that have a column of type string jsonb or text" do
      expect(subject).to include(comment_1)
      expect(subject).not_to include(comment_2)
    end

    it "generates a unique SQL query" do
      expect(subject.to_sql).to eq("SELECT \"decidim_comments_comments\".* FROM \"decidim_comments_comments\" WHERE (((((decidim_commentable_type::text LIKE '%#{deprecated_endpoint}%') OR (decidim_root_commentable_type::text LIKE '%#{deprecated_endpoint}%')) OR (decidim_author_type::text LIKE '%#{deprecated_endpoint}%')) OR (body::text LIKE '%#{deprecated_endpoint}%')) OR (decidim_participatory_space_type::text LIKE '%#{deprecated_endpoint}%'))")
    end

    context "when model cannot be constantized" do
      let(:model) { "Decidim::Comments::NotExistingModel" }

      it "returns an empty array" do
        expect(subject).to eq([])
      end
    end
  end
end
