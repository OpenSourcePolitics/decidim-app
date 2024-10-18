# frozen_string_literal: true

require "active_support/concern"
module ProposalExtraFieldExtends
  extend ActiveSupport::Concern

  included do
    after_save :update_decrypted_body

    private

    def update_decrypted_body
      update_columns(decrypted_private_body: private_body.to_s) if private_body.present?
    end
  end
end

Decidim::DecidimAwesome::ProposalExtraField.include(ProposalExtraFieldExtends)
