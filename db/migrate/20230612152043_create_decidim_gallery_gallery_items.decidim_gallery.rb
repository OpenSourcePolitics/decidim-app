# frozen_string_literal: true

# This migration comes from decidim_gallery (originally 20211019215121)

class CreateDecidimGalleryGalleryItems < ActiveRecord::Migration[6.0]
  def change
    create_table :decidim_gallery_gallery_items do |t|
      t.jsonb :title
      t.references :decidim_component, index: true

      t.string :decidim_author_type, null: false
      t.integer :decidim_author_id, null: false
      t.integer :decidim_user_group_id
      t.datetime :published_at
      t.jsonb :data, default: {}
      t.integer :weight, default: 0

      t.timestamps
    end
    add_index :decidim_gallery_gallery_items,
              [:decidim_author_id, :decidim_author_type],
              name: "index_decidim_gallery_gallery_items_on_decidim_author"
    add_index :decidim_gallery_gallery_items, :published_at
    add_index :decidim_gallery_gallery_items, :decidim_user_group_id
  end
end
