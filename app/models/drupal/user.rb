# frozen_string_literal: true

module Drupal
  class User < AbstractRecord
    self.table_name = "users"

    def site_web
      @site_web ||= ::Drupal::Field::SiteWeb.select("field_site_web_value").find_by(entity_type: "user", entity_id: uid)&.field_site_web_value
    end

    def presentation
      @presentation ||= ::Drupal::Field::Presentation.select("field_presentation_value").find_by(entity_type: "user", entity_id: uid)&.field_presentation_value
    end
  end
end
