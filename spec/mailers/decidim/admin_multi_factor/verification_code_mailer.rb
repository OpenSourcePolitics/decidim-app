# frozen_string_literal: true

require "spec_helper"

module Decidim
  module AdminMultiFactor
    describe VerificationCodeMailer do
      let(:organization) { create(:organization, name: { ca: "", en: "Test Organization", es: "" }) }
      let(:user) { create(:user, :confirmed, :admin, organization: organization) }
      let(:verification) { "1234" }
      let(:expires_at) { Date.tomorrow }

      describe "#verification_code" do
        let(:mail) { described_class.verification_code(email: user.email, verification: verification, organization: organization, expires_at: expires_at) }

        describe "email body" do
          it "includes the verification code" do
            expect(email_body(mail)).to include(verification)
          end

          it "includes organization name" do
            expect(email_body(mail)).to include("Test Organization")
          end

          it "includes expires_at" do
            expect(email_body(mail)).to include("It will expire")
          end
        end
      end
    end
  end
end
