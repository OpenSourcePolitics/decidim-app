# frozen_string_literal: true

namespace :decidim do
  desc "Set decrypted_private_body to existing extra fields"
  task set_decrypted_private_body: :environment do
    if Rails.env.development?
      PrivateBodyDecryptJob.perform_now
    else
      PrivateBodyDecryptJob.perform_later
    end
  end
end
