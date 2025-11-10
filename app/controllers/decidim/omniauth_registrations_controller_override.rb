# frozen_string_literal: true

module Decidim
  module OmniauthRegistrationsControllerOverride
    extend ActiveSupport::Concern

    included do
      include Decidim::AfterSignInActionHelper

      def create
        form_params = user_params_from_oauth_hash || params[:user]

        @form = form(Decidim::OmniauthRegistrationForm).from_params(form_params)
        @form.email ||= verified_email

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

      def sign_in_and_redirect(resource_or_scope, *args)
        strategy = request.env["omniauth.strategy"]
        provider = strategy.present? ? strategy.name : request.params["provider"]
        session["omniauth.provider"] = provider
        super
      end

      # Skip authorization handler by default
      def skip_first_login_authorization?
        ActiveRecord::Type::Boolean.new.cast(ENV.fetch("SKIP_FIRST_LOGIN_AUTHORIZATION", "false"))
      end

      # def failure
      # https://github.com/heartcombo/devise/blob/main/app/controllers/devise/omniauth_callbacks_controller.rb#L10
      # end

      protected

      def after_omniauth_failure_path_for(scope)
        request.params[stored_location_key_for(scope)] || session[stored_location_key_for(scope)] || request.referer || super
      end

      private

      def verified_email
        @verified_email ||= oauth_data.dig(:info, :email) || session.delete("devise.omniauth.verified_email")
      end

      # rubocop: disable Metrics/CyclomaticComplexity
      # rubocop: disable Metrics/PerceivedComplexity
      def after_sign_in_path_for(user)
        after_sign_in_action_for(user, request.params[:after_action]) if request.params[:after_action].present?

        if user.present? && user.blocked?
          check_user_block_status(user)
        elsif user.present? && !user.tos_accepted? && request.params[:after_action].present?
          session["tos_after_action"] = request.params[:after_action]
          super
        elsif !skip_first_login_authorization? && (first_login_and_not_authorized?(user) && !user.admin? && !pending_redirect?(user))
          decidim_verifications.first_login_authorizations_path
        else
          super
        end
      end
      # rubocop: enable Metrics/CyclomaticComplexity
      # rubocop: enable Metrics/PerceivedComplexity

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
