# frozen_string_literal: true

namespace :decidim do
  desc "Set decrypted_private_body to existing extra fields"
  task set_decrypted_private_body: :environment do
    extra_fields = Decidim::DecidimAwesome::ProposalExtraField.where(decrypted_private_body: nil).where.not(private_body: nil)
    if extra_fields.any?
      p "Extra fields to update: #{extra_fields.size}"
      count = 0
      extra_fields.find_each do |extra_field|
        extra_field.update(decrypted_private_body: extra_field.private_body.to_s)
        count += 1 if extra_field.decrypted_private_body_previous_change.present?
      end
      p "Extra fields updated: #{count}"
    end
  end
end
