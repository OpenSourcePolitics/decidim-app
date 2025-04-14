# frozen_string_literal: true

require "active_support/concern"

module SystemChecksCellExtends
  extend ActiveSupport::Concern

  included do
    # TODO : Remove this when we have a procedure to update the secret_key_base
    def correct_secret_key_base?
      Rails.application.secrets.secret_key_base.present?
    end
  end
end

Decidim::System::SystemChecksCell.include(SystemChecksCellExtends)
