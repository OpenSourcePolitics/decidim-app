# frozen_string_literal: true

module ApplicationControllerExtends
  extend ActiveSupport::Concern

  included do
    before_action :check_euf_completion, if: :current_user

    private

    def check_euf_completion
      return unless euf_completion_enforced?
      return if euf_whitelisted_path?

      missing_field = first_missing_euf_field(current_user)
      return unless missing_field

      existing = session["user_return_to"]
      stored = if existing.present?
                 existing
               elsif safe_euf_redirect_path?
                 request.fullpath
               end
      session[:euf_redirect_url] = stored if stored.present?
      flash[:alert] = t("decidim.extra_user_fields.force_euf_completion.alert")
      redirect_to "#{decidim.account_path}#user_#{missing_field}"
    end

    def euf_completion_enforced?
      Rails.application.secrets.dig(:decidim, :extra_user_fields, :force_euf_completion)
    end

    def euf_whitelisted_path?
      whitelisted_paths = ["/account", "/users/sign_out", "/rails/active_storage", "/decidim-packs"]
      whitelisted_paths.any? { |path| request.path.start_with?(path) }
    end

    def safe_euf_redirect_path?
      path = request.fullpath
      return false if path.include?("invitation_token")
      return false if path.include?("users/auth")
      return false if path.start_with?("/users/")

      true
    end

    def first_missing_euf_field(user)
      return if user.admin?
      return unless current_organization.extra_user_fields_enabled?

      [:country, :postal_code, :date_of_birth, :gender, :phone_number, :location, :underage].find do |field|
        current_organization.activated_extra_field?(field) &&
          user.extended_data[field.to_s].blank?
      end
    end
  end
end

ApplicationController.class_eval do
  include(ApplicationControllerExtends)
end
