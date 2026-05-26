# frozen_string_literal: true

module Decidim
  module Admin
    module Content
      class TreeController < Decidim::Admin::ApplicationController
        helper Decidim::IconHelper

        before_action :default_permissions
        before_action :relative_view_path
        helper_method :content_tree, :any_grand_children?
        layout "decidim/admin/content/tree"

        def index; end

        def export
          generator = Decidim::Content::TreeGenerator.new(
            organization: current_organization,
            include_object: false,
            location_type: :url,
            include_metadata: true,
            include_score: true,
            components_as_children: false
          )
          csv_data = generator.to_csv

          respond_to do |format|
            format.csv do
              send_data csv_data.string,
                        filename: "content_tree_#{Time.zone.now.strftime("%Y%m%d_%H%M%S")}.csv",
                        type: "text/csv"
            end
          end
        end

        def treemap
          respond_to do |format|
            format.html
            format.json { render json: content_treemap }
          end
        end

        def table; end

        private

        def default_permissions
          enforce_permission_to :update, :organization, organization: current_organization
        end

        def relative_view_path
          prepend_view_path "app/views/decidim/admin/content/tree"
        end

        def content_tree
          @content_tree ||= Decidim::Content::TreeGenerator.new(organization: current_organization).hash
        end

        def content_treemap
          Decidim::Content::TreeGenerator.new(
            organization: current_organization,
            include_object: false,
            include_metadata: false,
            include_score: true,
            components_as_children: true
          ).hash
        end

        def any_grand_children?(node)
          node[:children]&.any? { |child| child[:children]&.any? }
        end
      end
    end
  end
end
