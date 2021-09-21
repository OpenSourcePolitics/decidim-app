# frozen_string_literal: true

# This migration comes from decidim_navbar_links (originally 20190821120313)

class CreateDecidimNavbarLinksNavbarLinks < ActiveRecord::Migration[5.2]
  def change
    create_table :decidim_navbar_links_navbar_links do |t|
      t.references :decidim_organization, index: { name: "decidim_navbar_links_on_organization_id" }
      t.jsonb :title
      t.string :link
      t.string :target
      t.integer :weight
      t.timestamps
    end
  end
end
