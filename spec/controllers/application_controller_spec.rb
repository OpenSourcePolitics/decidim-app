# frozen_string_literal: true

require "spec_helper"

module Decidim
  describe ApplicationController do
    routes { Decidim::Core::Engine.routes }

    let(:organization) { create(:organization, extra_user_fields: { "enabled" => true }) }
    let(:user) { create(:user, :confirmed, organization:) }

    before do
      request.env["decidim.current_organization"] = organization
      request.env["devise.mapping"] = ::Devise.mappings[:user]
      sign_in user
      allow(controller).to receive(:current_organization).and_return(organization)
    end

    describe "#euf_completion_enforced?" do
      it "returns true when the secret is enabled" do
        allow(Rails.application.secrets).to receive(:dig)
          .with(:decidim, :extra_user_fields, :force_euf_completion)
          .and_return(true)
        expect(controller.send(:euf_completion_enforced?)).to be(true)
      end

      it "returns false when the secret is disabled" do
        allow(Rails.application.secrets).to receive(:dig)
          .with(:decidim, :extra_user_fields, :force_euf_completion)
          .and_return(false)
        expect(controller.send(:euf_completion_enforced?)).to be(false)
      end

      it "returns nil when the secret is not set" do
        allow(Rails.application.secrets).to receive(:dig)
          .with(:decidim, :extra_user_fields, :force_euf_completion)
          .and_return(nil)
        expect(controller.send(:euf_completion_enforced?)).to be_nil
      end
    end

    describe "#euf_whitelisted_path?" do
      {
        "/account" => true,
        "/users/sign_out" => true,
        "/rails/active_storage/blobs/xxx" => true,
        "/decidim-packs/main.js" => true,
        "/assemblies/my-assembly" => false,
        "/processes/my-process" => false,
        "/initiatives" => false,
        "/" => false
      }.each do |path, expected|
        it "returns #{expected} for #{path}" do
          allow(request).to receive(:path).and_return(path)
          expect(controller.send(:euf_whitelisted_path?)).to be(expected)
        end
      end
    end

    describe "#safe_euf_redirect_path?" do
      it "returns true for a normal assembly path" do
        allow(request).to receive(:fullpath).and_return("/assemblies/my-assembly")
        expect(controller.send(:safe_euf_redirect_path?)).to be(true)
      end

      it "returns true for a process path" do
        allow(request).to receive(:fullpath).and_return("/processes/my-process")
        expect(controller.send(:safe_euf_redirect_path?)).to be(true)
      end

      it "returns false for paths containing invitation_token" do
        allow(request).to receive(:fullpath).and_return("/users/invitation/accept?invitation_token=abc123")
        expect(controller.send(:safe_euf_redirect_path?)).to be(false)
      end

      it "returns false for omniauth paths" do
        allow(request).to receive(:fullpath).and_return("/users/auth/openid_connect/callback")
        expect(controller.send(:safe_euf_redirect_path?)).to be(false)
      end

      it "returns false for paths starting with /users/" do
        allow(request).to receive(:fullpath).and_return("/users/sign_in")
        expect(controller.send(:safe_euf_redirect_path?)).to be(false)
      end
    end

    describe "#first_missing_euf_field" do
      context "when the user is an admin" do
        let(:user) { create(:user, :admin, :confirmed, organization:) }

        it "returns nil" do
          expect(controller.send(:first_missing_euf_field, user)).to be_nil
        end
      end

      context "when extra_user_fields is not enabled on the organization" do
        let(:organization) { create(:organization, extra_user_fields: { "enabled" => false }) }

        it "returns nil" do
          expect(controller.send(:first_missing_euf_field, user)).to be_nil
        end
      end

      context "when all fields are filled" do
        before do
          allow(organization).to receive(:activated_extra_field?).and_return(true)
          user.update!(extended_data: {
                         "phone_number" => "+33612345678",
                         "country" => "FR",
                         "postal_code" => "75001",
                         "date_of_birth" => "1990-01-01",
                         "gender" => "female",
                         "location" => "Paris",
                         "underage" => false
                       })
        end

        it "returns nil" do
          expect(controller.send(:first_missing_euf_field, user)).to be_nil
        end
      end

      context "when phone_number is activated and missing" do
        before do
          allow(organization).to receive(:extra_user_fields_enabled?).and_return(true)
          allow(organization).to receive(:activated_extra_field?).and_return(false)
          allow(organization).to receive(:activated_extra_field?).with(:phone_number).and_return(true)
          user.update!(extended_data: { "phone_number" => nil })
        end

        it "returns :phone_number" do
          expect(controller.send(:first_missing_euf_field, user)).to eq(:phone_number)
        end
      end

      context "when country is activated and missing" do
        before do
          allow(organization).to receive(:extra_user_fields_enabled?).and_return(true)
          allow(organization).to receive(:activated_extra_field?).and_return(false)
          allow(organization).to receive(:activated_extra_field?).with(:country).and_return(true)
          user.update!(extended_data: { "country" => "" })
        end

        it "returns :country" do
          expect(controller.send(:first_missing_euf_field, user)).to eq(:country)
        end
      end

      context "when country and phone_number are activated but only phone_number is missing" do
        before do
          allow(organization).to receive(:extra_user_fields_enabled?).and_return(true)
          allow(organization).to receive(:activated_extra_field?).and_return(false)
          allow(organization).to receive(:activated_extra_field?).with(:country).and_return(true)
          allow(organization).to receive(:activated_extra_field?).with(:phone_number).and_return(true)
          user.update!(extended_data: { "country" => "FR", "phone_number" => nil })
        end

        it "returns :phone_number" do
          expect(controller.send(:first_missing_euf_field, user)).to eq(:phone_number)
        end
      end
    end
  end
end
