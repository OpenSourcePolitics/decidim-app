# This migration comes from decidim_category_enhanced (originally 20240222135216)
class AddColorsToDecidimCategories < ActiveRecord::Migration[6.1]
  def change
    change_table :decidim_categories do |t|
      t.string :text_color
      t.string :background_color
    end
  end
end
