# frozen_string_literal: true

require "spec_helper"
require "decidim/admin_creator"

module Decidim
  describe AdminCreator do
    let!(:organization) { create(:organization) }
    let(:name) { "John Doe" }
    let(:nickname) { "JD" }
    let(:email) { "john@example.org" }
    let(:password) { "decidim123456" }
    let(:organization_id) { organization.id.to_s }

    let(:environment) do
      {
        "organization_id" => organization_id,
        "name" => name,
        "nickname" => nickname,
        "email" => email,
        "password" => password
      }
    end

    it "creates admin" do
      expect { described_class.create!(environment) }.to change(Decidim::User, :count).by(1)
      expect(Decidim::User.last.admin).to eq(true)
      expect(Decidim::User.last.nickname).to eq(nickname)
      expect(Decidim::User.last.organization).to eq(organization)
      expect(Decidim::User.last.email).to eq(email)
    end

    context "when organization is missing" do
      let(:organization_id) { nil }

      it "creates admins with first organization" do
        expect { described_class.create!(environment) }.to change(Decidim::User, :count).by(1)
        expect(Decidim::User.last.admin).to eq(true)
        expect(Decidim::User.last.nickname).to eq(nickname)
        expect(Decidim::User.last.organization).to eq(organization)
        expect(Decidim::User.last.email).to eq(email)
      end
    end
  end
end
