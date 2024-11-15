# frozen_string_literal: true

Decidim::DecidimAwesome.configure do |config|
  config.weighted_proposal_voting = Rails.application.secrets.dig(:decidim, :decidim_awesome, :weighted_proposal_voting_enabled)&.to_sym
end
