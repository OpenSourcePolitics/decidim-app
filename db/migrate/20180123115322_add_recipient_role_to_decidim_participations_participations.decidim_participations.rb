# This migration comes from decidim_participations (originally 20180122152602)
class AddRecipientRoleToDecidimParticipationsParticipations < ActiveRecord::Migration[5.1]
  def change
    add_column :decidim_participations_participations, :recipient_role, :string
  end
end
