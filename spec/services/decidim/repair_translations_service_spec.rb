# frozen_string_literal: true

require "spec_helper"

describe Decidim::RepairTranslationsService do
  subject { described_class.new }

  let!(:comments) { create_list(:comment, 10) }
  let!(:proposals) { create_list(:proposal, 10) }

  describe "#translatable_resources" do
    it "returns all translatable resources" do
      expect(subject.send(:translatable_resources)).to match_array([
                                                                     Decidim::DummyResources::DummyResource,
                                                                     Decidim::ParticipatoryProcess,
                                                                     Decidim::ParticipatoryProcessGroup,
                                                                     Decidim::Assembly,
                                                                     Decidim::Pages::Page,
                                                                     Decidim::Meetings::Meeting,
                                                                     Decidim::Proposals::Proposal,
                                                                     Decidim::Budgets::Project,
                                                                     Decidim::Accountability::Result,
                                                                     Decidim::Debates::Debate,
                                                                     Decidim::Sortitions::Sortition,
                                                                     Decidim::Blogs::Post,
                                                                     Decidim::Conference,
                                                                     Decidim::Comments::Comment,
                                                                     Decidim::Initiative,
                                                                     Decidim::InitiativesType
                                                                   ])
      expect(subject.send(:translatable_resources)).not_to include(Decidim::DummyResources::CoauthorableDummyResource)
    end
  end

  describe "#translatable_previous_changes" do
    it "returns the previous changes for a translatable resource" do
      comment_changes = subject.send(:translatable_previous_changes, comments.first)
      proposal_changes = subject.send(:translatable_previous_changes, proposals.first)

      expect(comment_changes.keys).to eq(["body"])
      expect(comment_changes.values.first.map(&:class)).to eq([NilClass, ActiveSupport::HashWithIndifferentAccess])

      expect(proposal_changes.keys).to eq(%w(title body))
      expect(proposal_changes.values.first.map(&:class)).to eq([NilClass, ActiveSupport::HashWithIndifferentAccess])
    end
  end

  describe "#run" do
    it "calls repair_translations for each resource" do
      expect(Decidim::MachineTranslationResourceJob).to receive(:perform_later).at_least(20).times.and_return(true)

      subject.run
    end
  end

  describe ".run" do
    it "calls run" do
      expect(described_class.run).to be_a(Array)
    end
  end
end
