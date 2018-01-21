# This migration comes from decidim_participations (originally 20180115124110)
class AddTypeToParticipations < ActiveRecord::Migration[5.1]
  def change
    add_column :decidim_participations_participations, :participation_type,  :string
  end
end
