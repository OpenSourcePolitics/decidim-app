# This migration comes from decidim_participations (originally 20180116155719)
class AddJustificationToModeration < ActiveRecord::Migration[5.1]
  def change
    add_column :decidim_moderations, :justification, :text
  end
end
