# frozen_string_literal: true

module Decidim
  module System
    class DashboardController < Decidim::System::ApplicationController
      before_action :check_organizations_presence

      def show
        @organizations = Organization.all
        @db_size = db_size
      end

      def check_organizations_presence
        return if Organization.exists?

        redirect_to new_organization_path
      end

      private

      def db_size
        dbname = ActiveRecord::Base.connection.current_database
        sql = "SELECT pg_size_pretty(pg_database_size('#{dbname}'));"
        ActiveRecord::Base.connection.execute(sql)[0]["pg_size_pretty"]
      end
    end
  end
end
