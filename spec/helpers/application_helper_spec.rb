# frozen_string_literal: true

require "spec_helper"
require_relative "../../app/helpers/application_helper"

describe ApplicationHelper do
  let(:helper) do
    Class.new.tap do |v|
      v.extend(ApplicationHelper)
      v.extend(Cell::Helper::AssetHelper)
      v.extend(Decidim::OmniauthHelper)
      v.extend(Decidim::NeedsOrganization::InstanceMethods)
      v.extend(Webpacker::Helper)
    end
  end

  describe "#normalize_full_provider_name" do
    subject { helper.normalize_full_provider_name(provider) }

    let(:provider) { :provider_name }

    it { is_expected.to eq("provider_name") }

    context "when text is nil" do
      let(:provider) { nil }

      it "returns empty" do
        expect(subject).to be_empty
      end
    end
  end

  describe "#sso_provider_image" do
    subject { helper.sso_provider_image(provider, link_to_path, image_path) }

    let(:provider) { :provider_name }
    let(:link_to_path) { "/provider/path" }
    let(:image_path) { "media/images/FCboutons-10@2x.png" }

    it "returns a link with image" do
      expect(subject).to match("<a class=\"button--#{provider}\" rel=\"nofollow\" data-method=\"post\" href=\"#{link_to_path}\">")

      expect(subject).to match("packs-test/media/images/FCboutons-10@2x")
    end
  end
end
