# frozen_string_literal: true

class PrivateBodyDecryptJob < ApplicationJob
  queue_as :default

  def perform
    extra_fields = Decidim::DecidimAwesome::ProposalExtraField.where(decrypted_private_body: nil).where.not(private_body: nil)
    return unless extra_fields.any?

    Rails.logger.info "Extra fields to update: #{extra_fields.size}"
    count = 0
    extra_fields.find_each do |extra_field|
      extra_field.update(decrypted_private_body: extra_field.private_body.to_s)
      count += 1 if extra_field.decrypted_private_body_previous_change.present?
    end
    Rails.logger.info "Extra fields updated: #{count}"
  end
end
