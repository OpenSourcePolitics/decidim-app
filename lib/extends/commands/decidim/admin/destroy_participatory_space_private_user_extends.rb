# frozen_string_literal: true

require "active_support/concern"

module DestroyParticipatorySpacePrivateUserExtends
  extend ActiveSupport::Concern

  included do
    def call
      destroy_participatory_space_private_user
      run_after_hooks
      broadcast(:ok)
    end

    private

    def run_after_hooks
      # When private user is destroyed, a hook to destroy the follows of user on private non transparent assembly
      # or private participatory process and the follows of their children
      space = @participatory_space_private_user.privatable_to_type.constantize.find(@participatory_space_private_user.privatable_to_id)

      return unless space.private_space?

      return if space.respond_to?("is_transparent") && space.is_transparent?

      ids = []
      follows = Decidim::Follow.where(user: @participatory_space_private_user.decidim_user_id)
      ids << find_space_follow_id(follows, @participatory_space_private_user, space)
      ids << find_children_follows_ids(follows, space)
      follows.where(id: ids.flatten.compact).destroy_all if ids.present?
    end

    def find_space_follow_id(follows, participatory_space_private_user, space)
      follows.where(decidim_followable_type: participatory_space_private_user.privatable_to_type)
             .where(decidim_followable_id: space.id)
        &.first&.id
    end

    def find_children_follows_ids(follows, space)
      follows.map do |follow|
        object = find_object_followed(follow).presence
        next unless object.respond_to?("decidim_component_id")

        follow.id if space.components.ids.include?(object.decidim_component_id)
      end
    end

    def find_object_followed(follow)
      follow.decidim_followable_type.constantize.find(follow.decidim_followable_id)
    end
  end
end

Decidim::Admin::DestroyParticipatorySpacePrivateUser.include(DestroyParticipatorySpacePrivateUserExtends)
