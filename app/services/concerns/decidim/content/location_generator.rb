# frozen_string_literal: true

module Decidim
  module Content
    module LocationGenerator
      extend ActiveSupport::Concern
      included do
        def location_for(instance, location_type = :path)
          # TODO : create options for path versus url

          raise "Unsupported location type #{location_type}" unless [:path, :url].include?(location_type)
          raise "Organization attribute is required to generate data for :url location type" if location_type == :url && try(:organization).nil?

          front_key = location_type
          admin_key = "admin_#{location_type}".to_sym

          case instance.class.name
          when "Decidim::Organization"
            {
              front_key => send("base_#{location_type}"),
              admin_key => send("admin_base_#{location_type}")
            }
          when "Decidim::Component"
            {
              front_key => Decidim::EngineRouter.main_proxy(instance).send("root_#{location_type}"),
              admin_key => Decidim::EngineRouter.admin_proxy(instance).send("root_#{location_type}")
            }
          when "Decidim::ParticipatoryProcessGroup"
            {
              front_key => compute_location(
                location: Decidim::ParticipatoryProcesses::Engine.routes.url_helpers.participatory_process_group_path(instance),
                location_type:
              ),
              admin_key => compute_location(
                location: Decidim::ParticipatoryProcesses::AdminEngine.routes.url_helpers.edit_participatory_process_group_path(instance),
                location_type:
              )
            }
          when "Decidim::InitiativesType"
            {
              admin_key => compute_location(
                location: Decidim::Initiatives::AdminEngine.routes.url_helpers.edit_initiatives_type_path(instance),
                location_type:
              )
            }
          when "Decidim::InitiativesTypeScope"
            {
              admin_key => compute_location(
                location: Decidim::Initiatives::AdminEngine.routes.url_helpers.edit_initiatives_type_initiatives_type_scope_path(instance, id: instance.id),
                location_type:
              )
            }
          else
            # TODO: add a rescue for missing route or missing manifest :
            #   - advise to add another case in this method with the correct routes
            #   - return nil or empty hash while it's not implemented, instead of raising an error

            resource_locator_presenter = Decidim::ResourceLocatorPresenter.new(instance)
            {
              front_key => compute_location(
                location: resource_locator_presenter.path,
                location_type:
              ),
              admin_key => compute_location(
                location: resource_locator_presenter.edit,
                location_type:
              )
            }
          end
        end

        def compute_location(location:, location_type: :path, admin: false)
          # use the admin argument if you need to add "/admin" before the location argument
          joiner_class = location_type == :url ? URI : File
          prefix_method = admin ? "admin_" : ""
          base_location = send("#{prefix_method}base_#{location_type}")
          joiner_class.join(base_location, location).to_s
        end

        def base_path
          @base_path ||= Decidim::Core::Engine.routes.url_helpers.root_path
        end

        def base_url
          @base_url ||= switch_url_port(Decidim::Core::Engine.routes.url_helpers.root_url(host: organization.host))
        end

        def admin_base_path
          @admin_base_path ||= Decidim::Admin::Engine.routes.url_helpers.root_path
        end

        def admin_base_url
          @admin_base_url ||= switch_url_port(Decidim::Admin::Engine.routes.url_helpers.root_url(host: organization.host))
        end

        def switch_url_port(url)
          if Rails.env.development? || Rails.env.test?
            url_with_port = URI(url)
            url_with_port.port = Rails::Server::Options.new.parse!(ARGV)[:Port]
            url_with_port.to_s
          else
            url
          end
        end
      end
    end
  end
end
