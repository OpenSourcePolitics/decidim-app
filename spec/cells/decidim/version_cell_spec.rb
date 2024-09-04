# frozen_string_literal: true

require "spec_helper"

describe Decidim::VersionCell, type: :cell do
  controller Decidim::ApplicationController

  subject do
    cell("decidim/version", version, versioned_resource: meeting, index: index, versions_path: -> { versions_path }).call
  end

  let!(:assembly) { create(:assembly, :published, slug: "introduction-transfer") }
  let!(:component) { create(:component, manifest_name: "meetings", participatory_space: assembly) }
  let!(:meeting) { create(:meeting, :published, title: { en: "Meeting test" }, component: component) }
  let!(:version) { PaperTrail::Version.create!(item: meeting, event: "update", object_changes: "number: 2'%3Cmarquee%20onstart=alert(1)%3Ex") }
  let(:index) { "2'%3Cmarquee%20onstart=alert(1)%3Ex" }
  let(:versions_path) { "/assemblies/#{assembly.slug}/f/24/meetings/#{meeting.id}/versions/#{index}" }

  it "sanitizes the version number" do
    expect(subject).to have_link("Show all versions", href: "/assemblies/introduction-transfer/f/24/meetings/#{meeting.id}/versions/2'%3Cmarquee%20onstart=alert(1)%3Ex")

    expect(subject).not_to have_content("onstart=alert(1)")
  end
end
