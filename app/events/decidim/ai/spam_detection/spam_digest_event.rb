# frozen_string_literal: true

module Decidim
  module Ai
    module SpamDetection
      class SpamDigestEvent < Decidim::Events::BaseEvent
        include Decidim::Events::EmailEvent

        def self.types
          [:email, :notification]
        end

        def resource
          return @resource unless @resource.is_a?(Decidim::Organization)

          OpenStruct.new(organization: @resource)
        end

        def email_intro
          I18n.t(
            "decidim.ai.spam_detection.digest.summary",
            count: spam_count,
            frequency_label:
          )
        end

        def notification_title
          email_intro
        end

        def email_subject
          I18n.t(
            "decidim.ai.spam_detection.digest.subject",
            count: spam_count,
            frequency_label:
          )
        end

        def resource_title
          org_name =
            organization.name[I18n.locale.to_s].presence ||
            organization.name.dig("machine_translations", I18n.locale.to_s).presence ||
            organization.name["en"].presence ||
            organization.name.values.compact.first

          I18n.t("decidim.ai.spam_detection.digest.title", organization: org_name)
        end

        def resource_locator
          helpers = Decidim::Core::Engine.routes.url_helpers
          host = Decidim::Organization.first&.host || "localhost"

          Struct.new(:path, :url).new(
            resource_path,
            helpers.root_url(host:, protocol: "http")
          )
        end

        def resource_path(_organization = nil)
          Decidim::Core::Engine.routes.url_helpers.admin_moderations_path
        rescue NoMethodError
          Decidim::Core::Engine.routes.url_helpers.root_path
        end

        def show_extended_information?
          false
        end

        def organization
          if @resource.is_a?(Decidim::Organization)
            @resource
          elsif @resource.respond_to?(:organization)
            @resource.organization # user.organization
          elsif @resource.respond_to?(:component)
            @resource.component.participatory_space.organization
          else
            Decidim::Organization.first
          end
        end

        private

        def spam_count
          extra[:spam_count] || 0
        end

        def frequency_label
          I18n.t("decidim.ai.spam_detection.digest.frequency_label.#{extra[:frequency] || "daily"}")
        end
      end
    end
  end
end
