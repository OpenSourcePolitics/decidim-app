# frozen_string_literal: true
# This migration comes from decidim_ludens (originally 20221229185753)

class AddDocumentationToDecidimParticipativeActions < ActiveRecord::Migration[6.0]
  def up
    add_column :decidim_participative_actions, :documentation, :string
  end

  def down
    remove_column :decidim_participative_actions, :documentation
  end
end
