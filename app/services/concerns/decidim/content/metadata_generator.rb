# frozen_string_literal: true

module Decidim
  module Content
    module MetadataGenerator
      extend ActiveSupport::Concern
      included do
        def metadata_for(instance)
          {
            labels: labels_for(instance),
            stats: stats_for(instance)
          }
        end

        def labels_for(instance)
          labels = {}
          labels.merge!(component_type(instance)) if instance.is_a?(Decidim::Component)
          labels.merge!(private_space(instance)) if instance.is_a?(Decidim::HasPrivateUsers)
          labels.merge!(published(instance)) if instance.is_a?(Decidim::Publicable)
          labels
        end

        def stats_for(instance)
          stats = {}
          stats.merge!(component_stats(instance)) if instance.is_a?(Decidim::Component)
          stats
        end

        private

        def published(instance)
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
          {
            private: {
              value: instance.private_space ? "private" : "public",
              text: instance.private_space ? I18n.t("decidim.admin.content.tree.label.private") : I18n.t("decidim.admin.content.tree.label.public"),
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

        def component_stats(component)
          rejected_stats = []
          case component.manifest_name
          when "proposals"
            rejected_stats = [:proposals_accepted]
          end
          component.manifest.stats.except(rejected_stats).with_context(component).map do |stat_title, stat_number|
            [
              stat_title, 
              {
                value: stat_number,
                text: stat_title.to_s.chomp("_count").humanize,
                level: "info"
              }
            ]
          end.to_h
        end
      end
    end
  end
end
