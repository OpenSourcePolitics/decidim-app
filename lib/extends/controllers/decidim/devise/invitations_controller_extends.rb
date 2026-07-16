# frozen_string_literal: true

module ApplicationInvitationsControllerExtends
  extend ActiveSupport::Concern

  included do
    def after_accept_path_for(resource)
      private_user = Decidim::ParticipatorySpacePrivateUser
                     .where(user: resource)
                     .order(created_at: :desc)
                     .first

      if private_user&.privatable_to.present?
        space = private_user.privatable_to
        destination = case space
                      when Decidim::Assembly
                        decidim_assemblies.assembly_path(space.slug)
                      when Decidim::ParticipatoryProcess
                        decidim_participatory_processes.participatory_process_path(space.slug)
                      end
        store_location_for(resource, destination) if destination.present?
      end

      invite_redirect_path || after_sign_in_path_for(resource)
    end
  end
end

Decidim::Devise::InvitationsController.class_eval do
  include(ApplicationInvitationsControllerExtends)
end
