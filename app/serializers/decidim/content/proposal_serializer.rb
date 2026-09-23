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
          **body_attributes,
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

      def body_attributes
        {}.tap do |attrs|
          attrs.merge!(public_body_attributes) if proposal_custom_fields?
          attrs.merge!(private_body_attributes) if proposal_private_custom_fields?
        end
      end

      def public_body_attributes
        {}.tap do |attrs|
          original_body = normalize_translated_attribute(resource.try(:body))

          attrs[:body] = original_body

          if original_body.is_a?(Hash)
            if proposal_custom_fields?
              translated_custom_fields = original_body.transform_values { |text| parse_custom_fields_body(text) }
              attrs[:body] = translated_custom_fields.each_with_object({}) do |(key, custom_fields), result|
                result[key] = if custom_fields.present? && custom_fields.is_a?(Array)
                                convert_custom_fields_to_html(custom_fields)
                              else
                                convert_newlines_to_html(original_body[key])
                              end
              end
              attrs[:body_custom_fields] = translated_custom_fields
            else
              attrs[:body] = original_body.transform_values { |text| convert_newlines_to_html(text) }
            end
          end
        end
      end

      def private_body_attributes
        {}.tap do |attrs|
          # Private body should not be a translation Hash
          private_custom_fields = parse_custom_fields_body(resource.try(:private_body))
          attrs[:private_body] = convert_custom_fields_to_html(private_custom_fields)
          attrs[:private_body_custom_fields] = private_custom_fields
        end
      end

      def parse_custom_fields_body(text)
        return [] unless text.present? && text.starts_with?("<xml>")

        doc = Nokogiri::XML.fragment(text, &:noblanks)

        dl = doc.at_css("dl")
        return [] if dl.nil?

        dl.css("dt").map do |dt|
          {}.tap do |h|
            h[:title] = dt.text.strip
            dd = dl.at_css("dd[id='#{dt["name"]}']")
            h[:value] = dd&.text&.strip
          end
        end
      end

      def convert_custom_fields_to_html(fields)
        html = ""
        fields.each do |field|
          html += "<strong>#{field[:title]}</strong><br/>"
          html += "#{convert_newlines_to_html(field[:value])}<br/><br/>"
        end
        html
      end
    end
  end
end
