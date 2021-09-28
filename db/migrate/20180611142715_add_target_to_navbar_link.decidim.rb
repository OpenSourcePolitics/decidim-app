# frozen_string_literal: true

# This migration comes from decidim (originally 20180110144519)
class AddTargetToNavbarLink < ActiveRecord::Migration[5.1]
  def change
    add_column :decidim_navbar_links, :target, :string
  end
end
