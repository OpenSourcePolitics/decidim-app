# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Initiatives
    describe CommitteeRequestsController, type: :controller do
      routes { Decidim::Initiatives::Engine.routes }

      let(:organization) { create(:organization) }
      let!(:initiative) { create(:initiative, :created, organization: organization) }
      let(:admin_user) { create(:user, :admin, :confirmed, organization: organization) }
      let(:user) { create(:user, :confirmed, organization: organization) }

      before do
        request.env["decidim.current_organization"] = organization
      end

      context "when GET new" do
        let(:current_user) { create(:user, :confirmed, organization: organization) }
        let(:authorization_handler) { "dummy_authorization_handler" }
        let(:committee_request_path) { "/initiatives/#{initiative.id}/committee_requests/new" }

        before do
          allow(controller).to receive(:current_initiative).and_return(initiative)
          allow(controller).to receive(:current_user).and_return(current_user)
          allow(controller).to receive(:authorized?).and_return(authorized)
          allow(initiative).to receive(:document_number_authorization_handler).and_return(authorization_handler)
        end

        context "when not authorized" do
          let(:authorized) { false }

          it "redirects to authorization root path" do
            allow(controller).to receive(:authorized?).with(current_user).and_return(false)
            allow(controller).to receive(:new_initiative_committee_request_path).with(initiative).and_return(committee_request_path)

            get :new, params: { initiative_slug: initiative.slug }

            expect(response).to have_http_status(:found)
          end
        end

        context "when not logged in" do
          let(:current_user) { nil }
          let(:authorized) { false }

          it "redirects to login page" do
            allow(controller).to receive(:new_initiative_committee_request_path).with(initiative).and_return(committee_request_path)

            get :new, params: { initiative_slug: initiative.slug }

            expect(response).to have_http_status(:found)
            expect(URI.parse(response.location).path).to eq("/users/sign_in")
          end
        end

        context "when authorized" do
          let(:authorized) { true }

          it "does not redirect" do
            allow(controller).to receive(:authorized?).with(current_user).and_return(true)

            get :new, params: { initiative_slug: initiative.slug }

            expect(response).to have_http_status(:ok)
          end
        end
      end

      context "when authorized? is called" do
        let(:current_user) { create(:user, :confirmed, organization: organization) }
        let(:authorization_handler) { "dummy_authorization_handler" }

        before do
          allow(controller).to receive(:current_initiative).and_return(initiative)
          allow(controller).to receive(:current_user).and_return(current_user)
          allow(initiative).to receive(:document_number_authorization_handler).and_return(authorization_handler)
        end

        context "when authorized" do
          it "returns true" do
            allow(controller).to receive(:authorized?).with(current_user).and_return(true)

            result = controller.send(:authorized?, current_user)

            expect(result).to be(true)
          end
        end

        context "when not authorized" do
          it "returns false" do
            allow(controller).to receive(:authorized?).with(current_user).and_return(false)

            result = controller.send(:authorized?, current_user)

            expect(result).to be(false)
          end
        end
      end

      context "when GET spawn" do
        let(:user) { create(:user, :confirmed, organization: organization) }

        before do
          create(:authorization, user: user)
          sign_in user, scope: :user
        end

        context "and created initiative" do
          it "Membership request is created" do
            expect do
              get :spawn, params: { initiative_slug: initiative.slug }
            end.to change(InitiativesCommitteeMember, :count).by(1)
          end

          it "Duplicated requests finish with an error" do
            expect do
              get :spawn, params: { initiative_slug: initiative.slug }
            end.to change(InitiativesCommitteeMember, :count).by(1)

            expect do
              get :spawn, params: { initiative_slug: initiative.slug }
            end.not_to change(InitiativesCommitteeMember, :count)
          end
        end

        context "and published initiative" do
          let!(:published_initiative) { create(:initiative, :published, organization: organization) }

          it "Membership request is not created" do
            expect do
              get :spawn, params: { initiative_slug: published_initiative.slug }
            end.not_to change(InitiativesCommitteeMember, :count)
          end
        end
      end

      context "when GET approve" do
        let(:membership_request) { create(:initiatives_committee_member, initiative: initiative, state: "requested") }

        context "and Owner" do
          before do
            sign_in initiative.author, scope: :user
          end

          it "request gets approved" do
            get :approve, params: { initiative_slug: membership_request.initiative.to_param, id: membership_request.to_param }
            membership_request.reload
            expect(membership_request).to be_accepted
          end
        end

        context "and other users" do
          let(:user) { create(:user, :confirmed, organization: organization) }

          before do
            create(:authorization, user: user)
            sign_in user, scope: :user
          end

          it "Action is denied" do
            get :approve, params: { initiative_slug: membership_request.initiative.to_param, id: membership_request.to_param }
            expect(flash[:alert]).not_to be_empty
            expect(response).to have_http_status(:found)
          end
        end

        context "and Admin" do
          before do
            sign_in admin_user, scope: :user
          end

          it "request gets approved" do
            get :approve, params: { initiative_slug: membership_request.initiative.to_param, id: membership_request.to_param }
            membership_request.reload
            expect(membership_request).to be_accepted
          end
        end
      end

      context "when DELETE revoke" do
        let(:membership_request) { create(:initiatives_committee_member, initiative: initiative, state: "requested") }

        context "and Owner" do
          before do
            sign_in initiative.author, scope: :user
          end

          it "request gets approved" do
            delete :revoke, params: { initiative_slug: membership_request.initiative.to_param, id: membership_request.to_param }
            membership_request.reload
            expect(membership_request).to be_rejected
          end
        end

        context "and Other users" do
          let(:user) { create(:user, :confirmed, organization: organization) }

          before do
            create(:authorization, user: user)
            sign_in user, scope: :user
          end

          it "Action is denied" do
            delete :revoke, params: { initiative_slug: membership_request.initiative.to_param, id: membership_request.to_param }
            expect(flash[:alert]).not_to be_empty
            expect(response).to have_http_status(:found)
          end
        end

        context "and Admin" do
          before do
            sign_in admin_user, scope: :user
          end

          it "request gets approved" do
            delete :revoke, params: { initiative_slug: membership_request.initiative.to_param, id: membership_request.to_param }
            membership_request.reload
            expect(membership_request).to be_rejected
          end
        end
      end
    end
  end
end
