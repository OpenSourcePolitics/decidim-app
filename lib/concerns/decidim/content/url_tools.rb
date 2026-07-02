# frozen_string_literal: true

require "active_support/concern"

module Decidim
  module Content
    module UrlTools
      extend ActiveSupport::Concern
      included do
        def switch_url_port(url)
          if (Rails.env.development? || Rails.env.test?) && !defined?(Rails::Console)
            url_with_port = URI(url)
            url_with_port.port = Rails::Server::Options.new.parse!(ARGV)[:Port]
            url_with_port.to_s
          else
            url
          end
        end

        def blob_url(attachment, organization)
          return unless attachment.present? && attachment.respond_to?(:blob) && attachment.blob.present?

          # TODO : Optimize Decidim::Organization , ActiveStorage::Attachment and ActiveStorage::Blob eager load on each call

          # Another method is : resource..attached_uploader(:attachment_name).url

          # this gives the redirect url
          switch_url_port(Rails.application.routes.url_helpers.rails_blob_url(attachment.blob, host: organization.host))
        end
      end
    end
  end
end
