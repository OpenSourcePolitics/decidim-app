# frozen_string_literal: true

module Decidim
  module AfterSignInActionHelper
    extend ActiveSupport::Concern
    include Decidim::FormFactory

    included do
      def default_url_options
        url_options = {}
        url_options[:locale] = current_locale unless current_locale == default_locale.to_s
        url_options[:after_action] = request.params[:after_action] if request.params[:after_action].present?
        url_options
      end
    end

    def after_sign_in_action_for(user, action)
      return if user.blank?
      return unless action == "vote-initiative" && (scan = %r{/initiatives/i-(\d+)(\?.*)?}.match(read_stored_location_for(user)))

      initiative = Decidim::Initiative.find(scan[1])

      return unless allowed_to? :vote, :initiative, initiative: initiative, user: user, chain: permission_class_chain.push(Decidim::Initiatives::Permissions)

      form = form(Decidim::Initiatives::VoteForm).from_params(
        initiative: initiative,
        signer: user
      )

      Decidim::Initiatives::VoteInitiative.call(form) do
        on(:ok) do
          after_action_flash_message!(:secondary, "initiative_votes.create.success", "decidim.initiatives")
        end

        on(:invalid) do
          after_action_flash_message!(:error, "initiative_votes.create.error", "decidim.initiatives")
        end
      end
    end

    def read_stored_location_for(resource_or_scope)
      store_location_for(resource_or_scope, stored_location_for(resource_or_scope))
    end

    def after_action_flash_message!(level, key, scope)
      if is_a? DeviseController
        set_flash_message! level, key, { scope: scope }
      else
        flash.now[level] = t(key, scope: scope)
      end
    end
  end
end
