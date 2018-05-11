# This migration comes from decidim_initiatives (originally 20171011110714)
# frozen_string_literal: true

class AddBannerImageToInitiativeType < ActiveRecord::Migration[5.1]
  def change
    add_column :decidim_initiatives_types, :banner_image, :string
  end
end
