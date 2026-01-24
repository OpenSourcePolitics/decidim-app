# frozen_string_literal: true

# # frozen_string_literal: true
#
# namespace :decidim do
#   namespace :mailers do
#     desc "Adds the AI summary to the daily digest"
#     task spam_digest_daily: :environment do
#       puts "[Decidim-AI] Generating the daily AI spam digest..."
#       Decidim::Ai::SpamDetection::SpamDigestGeneratorJob.perform_now(:daily)
#     end
#
#     desc "Adds the AI summary to the weekly digest"
#     task spam_digest_weekly: :environment do
#       puts "[Decidim-AI] Generating the weekly AI spam digest..."
#       Decidim::Ai::SpamDetection::SpamDigestGeneratorJob.perform_now(:weekly)
#     end
#   end
# end
