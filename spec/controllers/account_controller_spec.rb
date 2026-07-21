# frozen_string_literal: true

require "spec_helper"

module Decidim
  describe Decidim::AccountController do
    routes { Decidim::Core::Engine.routes }

    let(:organization) { create(:organization, extra_user_fields: { "enabled" => true }) }
    let(:valid_params) do
      {
        user: {
          name: user.name,
          nickname: user.nickname,
          email: user.email,
          password: "",
          old_password: "",
          personal_url: "",
          about: "",
          locale: "fr",
          tos_agreement: "1"
        }
      }
    end
    let(:user) { create(:user, :confirmed, organization:) }

    before do
      request.env["decidim.current_organization"] = organization
      request.env["devise.mapping"] = ::Devise.mappings[:user]
      sign_in user
    end

    def stub_update_account_ok
      allow(Decidim::UpdateAccount).to receive(:call) do |_form, &block|
        callbacks = {}
        allow(controller).to receive(:on) { |ev, &cb| callbacks[ev] = cb }
        controller.instance_exec(&block)
        callbacks[:ok]&.call(false)
      end
    end

    describe "POST update redirection after EUF completion" do
      before { stub_update_account_ok }

      context "when session[:euf_redirect_url] is set (normal navigation interception)" do
        context "and points to an assembly" do
          before { session[:euf_redirect_url] = "/assemblies/my-assembly" }

          it "redirects to the assembly" do
            put :update, params: valid_params
            expect(response).to redirect_to("/assemblies/my-assembly")
          end

          it "clears euf_redirect_url from session" do
            put :update, params: valid_params
            expect(session[:euf_redirect_url]).to be_nil
          end
        end

        context "and points to a participatory process" do
          before { session[:euf_redirect_url] = "/processes/my-process" }

          it "redirects to the process" do
            put :update, params: valid_params
            expect(response).to redirect_to("/processes/my-process")
          end

          it "clears euf_redirect_url from session" do
            put :update, params: valid_params
            expect(session[:euf_redirect_url]).to be_nil
          end
        end
      end

      context "when stored_location_for is set (invitation flow)" do
        context "and points to an assembly" do
          before do
            allow(controller).to receive(:stored_location_for).and_return("/assemblies/private-assembly")
          end

          it "redirects to the assembly" do
            put :update, params: valid_params
            expect(response).to redirect_to("/assemblies/private-assembly")
          end
        end

        context "and points to a participatory process" do
          before do
            allow(controller).to receive(:stored_location_for).and_return("/processes/private-process")
          end

          it "redirects to the process" do
            put :update, params: valid_params
            expect(response).to redirect_to("/processes/private-process")
          end
        end
      end

      context "when both session[:euf_redirect_url] and stored_location_for are set" do
        before do
          session[:euf_redirect_url] = "/assemblies/from-session"
          allow(controller).to receive(:stored_location_for).and_return("/assemblies/from-devise")
        end

        it "prioritizes session[:euf_redirect_url]" do
          put :update, params: valid_params
          expect(response).to redirect_to("/assemblies/from-session")
        end
      end

      context "when neither session[:euf_redirect_url] nor stored_location_for are set" do
        it "redirects to account path" do
          put :update, params: valid_params
          expect(response).to redirect_to(account_path)
        end
      end

      context "when stored_location_for returns nil" do
        before { allow(controller).to receive(:stored_location_for).and_return(nil) }

        it "redirects to account path" do
          put :update, params: valid_params
          expect(response).to redirect_to(account_path)
        end
      end
    end
  end
end
