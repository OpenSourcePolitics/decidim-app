# frozen_string_literal: true

require "active_support/concern"

module NoAdminInitiativeFormExtends
  extend ActiveSupport::Concern

  included do
    validate :no_img_tag_in_description

    private

    def no_img_tag_in_description
      errors.add :description, I18n.t("errors.no_img_tag_in_description") if description =~ /(&lt;img|<img)/
    end
  end
end

Decidim::Initiatives::InitiativeForm.include(NoAdminInitiativeFormExtends)
