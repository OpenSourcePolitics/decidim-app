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
          sanitize(
            I18n.t(
              "decidim.ai.spam_detection.digest.summary",
              count: spam_count,
              frequency_label:,
              organization: translated_attribute(organization.name),
              moderations_url:
            )
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
          translated_attribute(organization.name)
        end

        def resource_locator
          helpers = Decidim::Core::Engine.routes.url_helpers
          host = organization.host || Decidim::Organization.first&.host || "localhost"

          Class.new do
            def initialize(path, url)
              @path = path
              @url = url
            end

            def path(_params = nil)
              @path
            end

            def url(_params = nil)
              @url
            end

            def route_name
              "organization"
            end
          end.new(
            resource_path,
            helpers.root_url(host:)
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

        private

        def moderations_url
          host = organization.host

          if host.blank?
            return "" unless Rails.env.local?

            host = "localhost:3000"
          elsif host == "localhost" && (Rails.env.local?)
            host = "localhost:3000"
          end

          protocol = Rails.env.production? ? "https" : "http"

          "#{protocol}://#{host}/admin/moderations"
        end

        def organization
          if @resource.is_a?(Decidim::Organization)
            @resource
          elsif @resource.respond_to?(:organization)
            @resource.organization
          elsif @resource.respond_to?(:component)
            @resource.component.participatory_space.organization
          else
            Decidim::Organization.first
          end
        end

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
