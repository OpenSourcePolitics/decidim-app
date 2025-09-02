# frozen_string_literal: true

require "active_support/concern"

module BaseOrganizationFormExtends
  extend ActiveSupport::Concern

  included do
    # TODO : Remove this when we have a procedure to update the secret_key_base
    def validate_secret_key_base_for_encryption
      true
    end
  end
end

Decidim::System::BaseOrganizationForm.include(BaseOrganizationFormExtends)
