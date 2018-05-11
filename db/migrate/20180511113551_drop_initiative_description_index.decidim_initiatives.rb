# This migration comes from decidim_initiatives (originally 20171102094250)
# frozen_string_literal: true

class DropInitiativeDescriptionIndex < ActiveRecord::Migration[5.1]
  def change
    remove_index :decidim_initiatives, :description
  end
end
