# This migration comes from decidim_participations (originally 20180119083730)
class AddPublishedDateInParticipations < ActiveRecord::Migration[5.1]
  def change
    add_column :decidim_participations_participations, :published_on, :date
  end
end
