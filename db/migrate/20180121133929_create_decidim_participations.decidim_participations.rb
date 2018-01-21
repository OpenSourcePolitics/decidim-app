# This migration comes from decidim_participations (originally 20161212110850)
# frozen_string_literal: true

class CreateDecidimParticipations < ActiveRecord::Migration[5.0]
  def change
    create_table :decidim_participations_participations do |t|
      t.text :title, null: false
      t.text :body, null: false
      t.references :decidim_feature, index: true, null: false, index: { name: "index_decidim_participations_on_decidim_feature_id" }
      t.references :decidim_author, index: true, index: { name: "index_decidim_participations_on_decidim_author_id" }
      t.references :decidim_category, index: true, index: { name: "index_decidim_participations_on_decidim_category_id" }
      t.references :decidim_scope, index: true, index: { name: "index_decidim_participations_on_decidim_scope_id" }

      t.timestamps
    end
  end
end
