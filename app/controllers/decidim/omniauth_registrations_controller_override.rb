# frozen_string_literal: true

module Decidim
  module OmniauthRegistrationsControllerOverride
    extend ActiveSupport::Concern

    included do
      def create
        form_params = user_params_from_oauth_hash || params[:user]

        @form = form(Decidim::OmniauthRegistrationForm).from_params(form_params)
        @form.email ||= verified_email

        existing_user = Decidim::User.find_by(email: verified_email, organization: current_organization)

        if existing_user
          handle_existing_user(existing_user)
        else
          Decidim::CreateOmniauthRegistration.call(@form, verified_email) do
            on(:ok) do |user|
              if user.active_for_authentication?
                sign_in_and_redirect user, event: :authentication
                provider_name = current_organization.enabled_omniauth_providers.dig(@form.provider.to_sym, :display_name) || @form.provider.titleize
                set_flash_message :notice, :success, kind: provider_name
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
              if user.errors[:email]
                set_flash_message :alert, :failure, kind: @form.provider.capitalize,
                                                    reason: t("decidim.devise.omniauth_registrations.create.email_already_exists")
              end
              session["devise.omniauth.verified_email"] = verified_email
              render :new
            end
          end
        end
      end

      protected

      def after_omniauth_failure_path_for(scope)
        request.params[stored_location_key_for(scope)] || session[stored_location_key_for(scope)] || request.referer || super
      end

      private

      def handle_existing_user(user)
        if user.blocked?
          flash[:error] = t("decidim.account.blocked")
          redirect_to decidim.root_path
        else
          user.confirm if !user.confirmed? && verified_email.present?

          identity = user.identities.find_or_initialize_by(
            provider: oauth_data[:provider],
            uid: oauth_data[:uid]
          )

          if identity.new_record?
            identity.organization = user.organization
            identity.save!
          end

          sign_in_and_redirect user, event: :authentication
          provider_name = current_organization.enabled_omniauth_providers.dig(@form.provider.to_sym, :display_name) || @form.provider.titleize
          set_flash_message :notice, :success, kind: provider_name
        end
      end

      def oauth_data
        @oauth_data ||= oauth_hash.slice(:provider, :uid, :info)
      end

      def oauth_hash
        raw_hash = request.env["omniauth.auth"]
        return {} unless raw_hash

        raw_hash.deep_symbolize_keys
      end

      def verified_email
        @verified_email ||= find_verified_email
      end

      def find_verified_email
        if oauth_data.present?
          session["oauth_data.verified_email"] = oauth_data.dig(:info, :email)
        else
          email_from_session = session["oauth_data.verified_email"]
          session.delete("oauth_data.verified_email")
          email_from_session
        end
      end
    end
  end
end
