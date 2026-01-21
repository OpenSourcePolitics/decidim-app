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
              I18n.locale => Decidim::ContentProcessor.parse(form.title, current_organization: form.current_organization).rewrite
            },
            body: {
              I18n.locale => Decidim::ContentProcessor.parse_with_processor(:inline_images, form.body, current_organization: form.current_organization).rewrite
            },
            component: form.component
          )

          proposal.taxonomizations = form.taxonomizations if form.taxonomizations.present?
          proposal.documents = form.documents if form.documents.present?
          if form.geocoded?
            proposal.latitude = form.latitude
            proposal.longitude = form.longitude
          end
          proposal.address = form.address if form.address.present?
          proposal.add_coauthor(@current_user)
          proposal.save!
          @attached_to = proposal
          proposal
        end
      end
    end
  end
end

Decidim::Proposals::CreateProposal.include(CreateProposalExtends)
