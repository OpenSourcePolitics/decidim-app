# frozen_string_literal: true

module OmniauthRegistrationsControllerExtends
  extend ActiveSupport::Concern

  included do
    def create
      form_params = user_params_from_oauth_hash || params[:user]

      @form = form(Decidim::OmniauthRegistrationForm).from_params(form_params)
      @form.email ||= verified_email

      Decidim::CreateOmniauthRegistration.call(@form, verified_email) do
        on(:ok) do |user|
          if user.active_for_authentication?
            sign_in_and_redirect user, event: :authentication
            set_flash_message :notice, :success, kind: @form.provider.capitalize
          else
            expire_data_after_sign_in!
            user.resend_confirmation_instructions unless user.confirmed?
            redirect_to decidim.root_path
            flash[:notice] = t("devise.registrations.signed_up_but_unconfirmed")
          end
        end

        on(:invalid) do
          set_flash_message :notice, :success, kind: @form.provider.capitalize
          session["devise.omniauth.verified_email"] = verified_email
          render :new
        end

        on(:error) do |user|
          set_flash_message :alert, :failure, kind: @form.provider.capitalize, reason: t("decidim.devise.omniauth_registrations.create.email_already_exists") if user.errors[:email]
          session["devise.omniauth.verified_email"] = verified_email
          render :new
        end
      end
    end

    private

    def verified_email
      @verified_email ||= oauth_data.dig(:info, :email) || session.delete("devise.omniauth.verified_email")
    end
  end
end

Decidim::Devise::OmniauthRegistrationsController.class_eval do
  include(OmniauthRegistrationsControllerExtends)
end
