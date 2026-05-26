# frozen_string_literal: true

module Decidim
  module Content
    module MetadataGenerator
      extend ActiveSupport::Concern
      included do
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

        def metadata_for(instance)
          {
            labels: labels_for(instance),
            stats: stats_for(instance)
          }
        end

        def labels_for(instance)
          labels = {}
          labels.merge!(hashtag(instance)) if instance.respond_to?(:hashtag) && instance.hashtag.present?
          labels.merge!(component_type(instance)) if instance.is_a?(Decidim::Component)
          labels.merge!(private_space(instance)) if instance.is_a?(Decidim::HasPrivateUsers)
          labels.merge!(published(instance)) if instance.is_a?(Decidim::Publicable)
          labels
        end

        def stats_for(instance, empty_values: false)
          stats = {}
          stats.merge!(component_stats(instance)) if instance.is_a?(Decidim::Component)
          stats.merge!(initiative_stats(instance)) if instance.is_a?(Decidim::Initiative)
          stats.merge!(participatory_space_stats(instance)) if instance.is_a?(Decidim::Participable)
          stats.merge!(followers_stats(instance)) if instance.is_a?(Decidim::Followable)
          stats.merge!(participatory_space_moderations_stats(instance)) if instance.is_a?(Decidim::Participable)
          stats.reject! { |_, stat| stat[:value].to_i.zero? } unless empty_values
          stats
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

        def hashtag(instance)
          {
            hashtag: {
              value: instance.hashtag,
              text: "##{instance.hashtag}",
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
          component.manifest.stats.except(rejected_stats).with_context(component).to_h do |stat_title, stat_number|
            [
              stat_title,
              {
                value: stat_number,
                text: stat_title.to_s.chomp("_count").humanize,
                level: "info"
              }
            ]
          end
        end

        def participatory_space_stats(space)
          {
            categories_count: {
              value: space.categories&.size || 0,
              text: I18n.t("decidim.admin.content.tree.stats.categories"),
              icon: "tags-line",
              level: "info"
            },
            components_count: {
              value: space.components&.size || 0,
              text: I18n.t("decidim.admin.content.tree.stats.components"),
              icon: "apps-2-line",
              level: "info"
            },
            attachments_count: {
              value: space.attachments&.size || 0,
              text: I18n.t("decidim.admin.content.tree.stats.attachments"),
              icon: "paperclip-line",
              level: "info"
            }
          }
        end

        def participatory_space_moderations_stats(space)
          moderations = Decidim::Moderation.where(participatory_space: space)
          {
            moderations_count: {
              value: moderations.size,
              text: I18n.t("decidim.admin.content.tree.stats.moderations"),
              icon: "flag-line",
              level: "info"
            },
            hidden_moderations_count: {
              value: moderations.hidden.size,
              text: I18n.t("decidim.admin.content.tree.stats.hidden_moderations"),
              icon: "eye-off-line",
              level: "warning"
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

        def initiative_stats(initiative)
          {
            signatures_count: {
              value: initiative.supports_count,
              text: I18n.t("decidim.admin.content.tree.stats.signatures"),
              icon: "thumb-up-line",
              level: "info"
            },
            authors_count: {
              value: initiative.author_users.size > 1 ? initiative.author_users.size : nil,
              text: I18n.t("decidim.admin.content.tree.stats.authors"),
              icon: "user-line",
              level: "info"
            },
            comments_count: {
              value: initiative.comments_count,
              text: I18n.t("decidim.admin.content.tree.stats.comments"),
              icon: "message-line",
              level: "info"
            }
          }
        end

        def followers_stats(instance)
          {
            followers_count: {
              value: instance.follows_count,
              text: I18n.t("decidim.admin.content.tree.stats.followers"),
              icon: "group-line",
              level: "info"
            }
          }
        end
      end
    end
  end
end
