# frozen_string_literal: true

require "active_support/concern"
module CreateProposalExtends
  extend ActiveSupport::Concern

  included do
    def create_proposal
      PaperTrail.request(enabled: false) do
        @proposal = Decidim.traceability.perform_action!(
          :create,
          Decidim::Proposals::Proposal,
          @current_user,
          visibility: "public-only"
        ) do
          proposal = Decidim::Proposals::Proposal.new(
            title: {
              I18n.locale => title_with_hashtags
            },
            body: {
              I18n.locale => body_with_hashtags
            },
            component: form.component
          )

          proposal.category = form.category if form.category_id.present?
          proposal.scope = form.scope if form.scope_id.present?
          proposal.documents = form.documents if form.documents.present?
          proposal.address = form.address if form.address.present?
          proposal.latitude = form.latitude if form.latitude.present?
          proposal.longitude = form.longitude if form.longitude.present?
          proposal.add_coauthor(@current_user, user_group:)
          proposal.save!
          @attached_to = proposal
          proposal
        end
      end
    end
  end
end

Decidim::Proposals::CreateProposal.include(CreateProposalExtends)
