# frozen_string_literal: true

module Decidim
  module Content
    module StatsGenerator
      extend ActiveSupport::Concern

      included do
        def stats_for(instance, empty_values: false) # rubocop:disable Metrics/CyclomaticComplexity
          stats = {}
          stats.merge!(organization_stats(instance)) if instance.is_a?(Decidim::Organization)
          stats.merge!(component_stats(instance)) if instance.is_a?(Decidim::Component)
          stats.merge!(initiative_stats(instance)) if instance.is_a?(Decidim::Initiative)
          stats.merge!(participatory_space_stats(instance)) if instance.is_a?(Decidim::Participable)
          stats.merge!(followers_stats(instance)) if instance.is_a?(Decidim::Followable)
          stats.merge!(participatory_space_moderations_stats(instance)) if instance.is_a?(Decidim::Participable)
          stats.reject! { |_, stat| stat[:value].to_i.zero? && !stat[:force_display] } unless empty_values
          stats
        end

        private

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

        def organization_stats(organization)
          {
            **organization_users_stats(organization),
            **organization_system_stats(organization),
            **organization_transversal_content_stats(organization)
          }
        end

        def organization_users_stats(organization)
          {
            **organization.user_entities.group(:type).count.sort.to_h.each.inject({}) do |stats, (type, count)|
              key = type.to_s.demodulize.underscore.pluralize
              stats.merge(
                key.to_sym => {
                  value: count || 0,
                  text: I18n.t("decidim.admin.content.tree.stats.organization.users.#{key}", count:, default: key.humanize),
                  level: "info"
                }
              )
            end,
            admins: {
              value: admin_count = organization.admins.count,
              text: I18n.t("decidim.admin.content.tree.stats.organization.users.admins", count: admin_count),
              level: admin_count.positive? ? "info" : "warning",
              force_display: true
            },
            **organization.users_with_any_role.group(:roles).count.each_with_object({}) do |(roles, count), stats|
              roles.each do |role|
                key = role.to_s.pluralize
                stats.merge!(
                  key.to_sym => {
                    value: count || 0,
                    text: I18n.t("decidim.admin.content.tree.stats.organization.users.#{key}", count:, default: key.humanize),
                    level: "info"
                  }
                ) { |_key, old_value, new_value| old_value + new_value }
              end
              stats
            end
          }
        end

        def organization_system_stats(organization)
          {
            authorizations: {
              value: authorizations_count = organization.available_authorizations.size,
              text: I18n.t("decidim.admin.content.tree.stats.organization.authorizations", count: authorizations_count),
              level: "info"
            },
            omniauth_providers: {
              value: omniauth_providers_count = organization.enabled_omniauth_providers.size,
              text: I18n.t("decidim.admin.content.tree.stats.organization.omniauth_providers", count: omniauth_providers_count),
              level: "info"
            }
          }
        end

        def organization_transversal_content_stats(organization)
          {
            scopes: {
              value: scopes_count = organization.scopes.count,
              text: I18n.t("decidim.admin.content.tree.stats.organization.scopes", count: scopes_count),
              level: "info"
            },
            areas: {
              value: areas_count = organization.areas.count,
              text: I18n.t("decidim.admin.content.tree.stats.organization.areas", count: areas_count),
              level: "info"
            },
            static_pages: {
              value: static_pages_count = organization.static_pages.count,
              text: I18n.t("decidim.admin.content.tree.stats.organization.static_pages", count: static_pages_count),
              level: "info"
            },
            static_page_topics: {
              value: static_page_topics_count = organization.static_page_topics.count,
              text: I18n.t("decidim.admin.content.tree.stats.organization.static_page_topics", count: static_page_topics_count),
              level: "info"
            }
          }
        end
      end
    end
  end
end
