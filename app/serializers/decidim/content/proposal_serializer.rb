# frozen_string_literal: true

module Decidim
  module Content
    # see : Decidim::Proposals::ProposalSerializer
    class ProposalSerializer < Decidim::Content::BaseContentSerializer
      def serialize
        {
          uid: uid(resource),
          authors: coauthors(resource).map { |author| uid(author) },
          category: uid(resource.try(:category)),
          scope: uid(Decidim::Scope.new(id: resource.try(:decidim_scope_id))),
          title: normalize_translated_attribute(resource.try(:title)),
          body: format_body,
          address: resource.try(:address),
          latitude: resource.try(:latitude),
          longitude: resource.try(:longitude),
          state: uid(resource.try(:proposal_state)),
          state_token: resource.try(:internal_state),
          reference: resource.try(:reference),
          answer: normalize_translated_attribute(resource.try(:answer)),
          answered_at: resource.try(:answered_at),
          votes_count: resource.try(:proposal_votes_count),
          endorsements_count: resource.try(:endorsements).try(:size),
          comments_count: resource.try(:comments_count),
          attachments_count: resource.try(:attachments).try(:size),
          followers_count: resource.try(:follows).try(:size),
          notes_count: resource.try(:proposal_notes_count),
          published_at: resource.try(:published_at),
          related_proposals: resource.linked_resources(:proposals, "copied_from_component").map { |proposal| uid(proposal) },
          related_meetings: resource.linked_resources(:meetings, "proposals_from_meeting").map { |meeting| uid(meeting) },
          is_amend: resource.try(:emendation?),
          original_proposal: uid(resource.try(:amendable)),
          withdrawn: resource.try(:withdrawn?),
          withdrawn_at: resource.try(:withdrawn_at),
          component: uid(resource.try(:component)),
          url: Decidim::ResourceLocatorPresenter.new(resource).url
        } # TODO : add custom fields (public & private)
      end

      # rubocop:disable Metrics/CyclomaticComplexity
      def format_body
        Rails.logger.debug { "format_body for proposal #{resource.id} - #{resource.title}" }
        original = normalize_translated_attribute(resource.try(:body))

        original.transform_values do |text|
          return text unless text.present? && text.starts_with?("<xml>")

          Rails.logger.debug { " -- text starts with <xml> and text is #{text}" }
          doc = Nokogiri::XML.fragment(text, &:noblanks)

          search_path = "xml > dl > *"
          return text unless doc.present? && (nodes = doc.search(search_path)).present?

          body = ""
          nodes.each do |node|
            node_text = node.text.strip
            case node.name
            when "dt"
              node_text = "<strong>#{node_text}</strong><br/>"
            when "dd"
              node_text = node_text.gsub("\n", "<br/>") if node["name"] == "textarea"
              node_text = "#{node_text}<br/><br/>"
            end
            body += node_text
          end
          body
        end
      end
      # rubocop:enable Metrics/CyclomaticComplexity
    end
  end
end
