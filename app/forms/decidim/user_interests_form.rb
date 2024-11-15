# frozen_string_literal: true

module Decidim
  # The form object that handles the data behind updating a user's
  # interests in their profile page.
  class UserInterestsForm < Form
    mimic :user

    attribute :scopes, Array[UserInterestScopeForm]

    def newsletter_notifications_at
      return unless newsletter_notifications

      Time.current
    end

    def map_model(user)
      self.scopes = user.organization.scopes.top_level.sort_by(&:weight).map do |scope|
        UserInterestScopeForm.from_model(scope: scope, user: user)
      end
    end
  end
end
