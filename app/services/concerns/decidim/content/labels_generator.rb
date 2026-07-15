# frozen_string_literal: true

module Decidim
  module Content
    module LabelsGenerator
      extend ActiveSupport::Concern

      included do
        include ActionView::Helpers::DateHelper

        INITIATIVE_STATE_ICON_MAP = {
          created: "draft-line",
          validating: "time-line",
          published: "pen-nib-line",
          discarded: "close-line",
          accepted: "thumb-up-line",
          rejected: "thumb-down-line"
        }.freeze

        INITIATIVE_STATE_LEVEL_MAP = {
          created: "info",
          validating: "warning",
          published: "success",
          discarded: "alert",
          accepted: "success",
          rejected: "alert"
        }.freeze

        def labels_for(instance)
          labels = {}
          labels.merge!(organization_labels(instance)) if instance.is_a?(Decidim::Organization)
          labels.merge!(hashtag(instance)) if instance.respond_to?(:hashtag) && instance.hashtag.present?
          labels.merge!(component_type(instance)) if instance.is_a?(Decidim::Component)
          labels.merge!(private_space(instance)) if instance.is_a?(Decidim::HasPrivateUsers)
          labels.merge!(published(instance)) if instance.is_a?(Decidim::Publicable)
          labels
        end

        private

        def published(instance)
          return initiative_state(instance) if instance.is_a?(Decidim::Initiative)

          if instance.published?
            value = "published"
            icon = "check-line"
            level = "success"
          else
            icon = "close-line"
            if instance.previously_published?
              value = "previously_published"
              level = "warning"
            else
              value = "unpublished"
              level = "alert"
            end
          end
          {
            published: {
              value:,
              text: I18n.t("decidim.admin.content.tree.label.#{value}"),
              icon:,
              level:
            }
          }
        end

        def private_space(instance)
          key = instance.private_space ? "private" : "public"
          {
            private: {
              value: key,
              text: I18n.t("decidim.admin.content.tree.label.#{key}"),
              icon: instance.private_space ? "eye-off-line" : "eye-line",
              level: instance.private_space ? "warning" : "success"
            }
          }
        end

        def component_type(instance)
          {
            component_type: {
              value: instance.manifest_name,
              text: I18n.t("decidim.components.#{instance.manifest_name}.name", default: instance.manifest_name.humanize),
              icon: "tools-line",
              level: "info"
            }
          }
        end

        def hashtag(instance)
          {
            hashtag: {
              value: instance.hashtag,
              text: "##{instance.hashtag}",
              level: "info"
            }
          }
        end

        def initiative_state(instance)
          {
            initiative_state: {
              value: instance.state,
              text: I18n.t("decidim.initiatives.admin_states.#{instance.state}"),
              icon: INITIATIVE_STATE_ICON_MAP[instance.state.to_sym],
              level: INITIATIVE_STATE_LEVEL_MAP[instance.state.to_sym] || "info"
            }
          }
        end

        def organization_labels(organization)
          {
            created_at: {
              text: I18n.t("decidim.admin.content.tree.stats.organization.created_at", time_ago: time_ago_in_words(organization.created_at)),
              icon: "time-line",
              level: "info"
            }
          }
        end
      end
    end
  end
end
