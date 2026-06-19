# frozen_string_literal: true

require "spec_helper"

module Decidim
  describe Decidim::Devise::InvitationsController do
    routes { Decidim::Core::Engine.routes }

    let(:organization) { create(:organization) }
    let(:user) { create(:user, :confirmed, organization:) }

    before do
      request.env["decidim.current_organization"] = organization
      request.env["devise.mapping"] = ::Devise.mappings[:user]
      sign_in user
      allow(controller).to receive(:after_sign_in_path_for).and_return("/account")
    end

    describe "#after_accept_path_for" do
      subject { controller.after_accept_path_for(user) }

      context "when the user has no private space membership" do
        it "does not store euf_redirect_url in session" do
          subject
          expect(session[:euf_redirect_url]).to be_nil
        end

        it "delegates to after_sign_in_path_for" do
          allow(controller).to receive(:after_sign_in_path_for).with(user).and_return("/account")
          expect(subject).to eq("/account")
          subject
        end
      end

      context "when the user is a member of a private assembly" do
        let(:assembly) { create(:assembly, :private, organization:) }

        before do
          create(:participatory_space_private_user, user:, privatable_to: assembly)
        end

        it "stores the assembly path in euf_redirect_url" do
          subject
          expect(session[:euf_redirect_url]).to eq("/assemblies/#{assembly.slug}")
        end

        it "delegates to after_sign_in_path_for" do
          allow(controller).to receive(:after_sign_in_path_for).with(user).and_return("/account")
          expect(subject).to eq("/account")
          subject
        end
      end

      context "when the user is a member of a private participatory process" do
        let(:participatory_process) { create(:participatory_process, :private, organization:) }

        before do
          create(:participatory_space_private_user, user:, privatable_to: participatory_process)
        end

        it "stores the participatory process path in euf_redirect_url" do
          subject
          expect(session[:euf_redirect_url]).to eq("/processes/#{participatory_process.slug}")
        end

        it "delegates to after_sign_in_path_for" do
          allow(controller).to receive(:after_sign_in_path_for).with(user).and_return("/account")
          expect(subject).to eq("/account")
          subject
        end
      end

      context "when the user has multiple private space memberships" do
        let(:assembly_old) { create(:assembly, :private, organization:) }
        let(:assembly_new) { create(:assembly, :private, organization:) }

        before do
          create(:participatory_space_private_user, user:, privatable_to: assembly_old,
                                                    created_at: 2.days.ago)
          create(:participatory_space_private_user, user:, privatable_to: assembly_new,
                                                    created_at: 1.day.ago)
        end

        it "stores the most recent membership's space path" do
          subject
          expect(session[:euf_redirect_url]).to eq("/assemblies/#{assembly_new.slug}")
        end
      end

      context "when invite_redirect param is present" do
        before do
          allow(controller).to receive(:params).and_return(
            ActionController::Parameters.new(invite_redirect: "/some/path")
          )
        end

        it "returns the invite_redirect path without delegating to after_sign_in_path_for" do
          expect(controller).not_to receive(:after_sign_in_path_for)
          expect(subject).to eq("/some/path")
        end
      end
    end
  end
end
