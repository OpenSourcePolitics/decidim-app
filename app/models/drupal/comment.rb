# frozen_string_literal: true

module Drupal
  class Comment < AbstractRecord
    self.table_name = "comment"

    def body
      @body ||= Drupal::Field::Body.select("comment_body_value").find_by(entity_type: "comment", entity_id: cid)&.comment_body_value
    end

    def user
      @user ||= Decidim::User.where("extended_data::jsonb @> :drupal", drupal: { drupal: { uid: uid } }.to_json).first
    end
  end
end
