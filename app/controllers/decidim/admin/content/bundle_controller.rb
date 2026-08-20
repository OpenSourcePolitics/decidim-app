# frozen_string_literal: true

module Decidim
  module Admin
    module Content
      class BundleController < Decidim::Admin::ApplicationController
        before_action :default_permissions

        def export
          zip_data = Decidim::Content::CsvBundler.new(organization: current_organization).export_to_archive

          respond_to do |format|
            format.zip do
              send_data zip_data.read,
                        filename: "#{current_organization.host}--content-bundle--#{Time.zone.now.strftime("%Y%m%d-%H%M%S")}.zip",
                        type: "application/zip"
            end
          end
        end

        private

        def default_permissions
          enforce_permission_to :update, :organization, organization: current_organization
        end
      end
    end
  end
end
