# frozen_string_literal: true

require "spec_helper"
require "decidim/create_system_admin"

module Decidim
  describe CreateSystemAdmin do
    let(:email) { "john@example.org" }
    let(:password) { "decidim123456" }

    let(:environment) do
      {
        "email" => email,
        "password" => password
      }
    end

    it "creates admin" do
      expect { described_class.create!(environment) }.to change(Decidim::System::Admin, :count).by(1)
      expect(Decidim::System::Admin.last.email).to eq(email)
    end
  end
end
