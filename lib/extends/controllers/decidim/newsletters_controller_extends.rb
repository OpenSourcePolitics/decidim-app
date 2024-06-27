# frozen_string_literal: true

require "active_support/concern"
module NewslettersExtends
  extend ActiveSupport::Concern

  included do
    def unsubscribe
      encryptor = Decidim::NewsletterEncryptor

      decrypted_string = encryptor.sent_at_decrypted(params[:u])
      user = Decidim::User.find_by(decidim_organization_id: current_organization.id, id: decrypted_string.split("-").first)
      sent_at_time = Time.zone.at(decrypted_string.split("-").second.to_i)

      if sent_at_time > Rails.application.secrets.dig(:decidim, :newsletters_unsubscribe_timeout).days.ago
        Decidim::UnsubscribeSettings.call(user) do
          on(:ok) do
            flash.now[:notice] = t("newsletters.unsubscribe.success", scope: "decidim")
          end

          on(:invalid) do
            flash.now[:alert] = t("newsletters.unsubscribe.error", scope: "decidim")
            render action: :unsubscribe
          end
        end
      else
        flash.now[:alert] = t("newsletters.unsubscribe.token_error", scope: "decidim")
        render action: :unsubscribe
      end
    end
  end
end

Decidim::NewslettersController.include(NewslettersExtends)
