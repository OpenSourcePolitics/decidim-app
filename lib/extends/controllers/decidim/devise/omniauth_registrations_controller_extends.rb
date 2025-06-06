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

    def sign_in_and_redirect(resource_or_scope, *args)
      strategy = request.env["omniauth.strategy"]
      provider = strategy.name
      session["omniauth.provider"] = provider
      session["omniauth.#{provider}.logout_policy"] = strategy.options[:logout_policy] if strategy.options[:logout_policy].present?
      session["omniauth.#{provider}.logout_path"] = strategy.options[:logout_path] if strategy.options[:logout_path].present?
      super
    end

    def after_sign_in_path_for(user)
      if user.present? && user.blocked?
        check_user_block_status(user)
      elsif !skip_first_login_authorization? && (first_login_and_not_authorized?(user) && !user.admin? && !pending_redirect?(user))
        decidim_verifications.first_login_authorizations_path
      else
        super
      end
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
  end
end

Decidim::Devise::OmniauthRegistrationsController.class_eval do
  include(OmniauthRegistrationsControllerExtends)
end
