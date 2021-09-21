# frozen_string_literal: true

# This migration comes from decidim (originally 20180112110646)
class AddWeightToNavbarLink < ActiveRecord::Migration[5.1]
  def change
    add_column :decidim_navbar_links, :weight, :integer
  end
end
