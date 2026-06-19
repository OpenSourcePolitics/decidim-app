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

    def stub_update_account(event, *args)
      allow(Decidim::UpdateAccount).to receive(:call) do |_form, &block|
        callbacks = {}
        allow(controller).to receive(:on) { |ev, &cb| callbacks[ev] = cb }
        controller.instance_exec(&block)
        callbacks[event]&.call(*args)
      end
    end

    describe "PUT update" do
      context "when UpdateAccount succeeds" do
        before { stub_update_account(:ok, false) }

        context "and euf_redirect_url is stored in session" do
          before { session[:euf_redirect_url] = "/assemblies/some-assembly" }

          it "redirects to the stored euf_redirect_url" do
            put :update, params: valid_params
            expect(response).to redirect_to("/assemblies/some-assembly")
          end

          it "clears euf_redirect_url from session" do
            put :update, params: valid_params
            expect(session[:euf_redirect_url]).to be_nil
          end

          it "shows the success flash" do
            put :update, params: valid_params
            expect(flash[:notice]).to be_present
          end
        end

        context "and euf_redirect_url is a participatory process path" do
          before { session[:euf_redirect_url] = "/processes/some-process" }

          it "redirects to the stored process path" do
            put :update, params: valid_params
            expect(response).to redirect_to("/processes/some-process")
          end
        end

        context "and no euf_redirect_url is stored in session" do
          it "redirects to account path" do
            put :update, params: valid_params
            expect(response).to redirect_to(account_path)
          end
        end
      end

      context "when UpdateAccount fails" do
        before do
          stub_update_account(:invalid, false)
          session[:euf_redirect_url] = "/assemblies/some-assembly"
        end

        it "renders the show template" do
          put :update, params: valid_params
          expect(response).to render_template(:show)
        end

        it "keeps euf_redirect_url in session so the user can retry" do
          put :update, params: valid_params
          expect(session[:euf_redirect_url]).to eq("/assemblies/some-assembly")
        end

        it "shows the error flash" do
          put :update, params: valid_params
          expect(flash[:alert]).to be_present
        end
      end
    end
  end
end
