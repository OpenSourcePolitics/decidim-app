# frozen_string_literal: true

module Extends
  module Proposals
    module ProposalSerializerExtends
      WEIGHT_LABELS = {
        "1" => :votes_red_disapproval,
        "2" => :votes_yellow_neutral,
        "3" => :votes_green_approval
      }.freeze

      def serialize
        inject_after(super, :votes, vote_weights_summary)
      end

      private

      def inject_after(hash, after_key, extra)
        hash.each_with_object({}) do |(k, v), result|
          result[k] = v
          result.merge!(extra) if k == after_key
        end
      end

      def vote_weights_summary
        return {} unless vote_weights_enabled?

        extra_field = Decidim::DecidimAwesome::ProposalExtraField
                      .find_by(decidim_proposal_id: proposal.id, decidim_proposal_type: proposal.class.name)

        return {} unless extra_field&.vote_weight_totals

        WEIGHT_LABELS.each_with_object({}) do |(weight, label), result|
          result[label] = extra_field.vote_weight_totals[weight].to_i
        end
      end

      def vote_weights_enabled?
        proposal.component.settings.respond_to?(:awesome_voting_manifest) &&
          proposal.component.settings.awesome_voting_manifest.present?
      end
    end
  end
end

Decidim::Proposals::ProposalSerializer.prepend(
  Extends::Proposals::ProposalSerializerExtends
)
