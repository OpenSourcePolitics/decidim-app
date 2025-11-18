# frozen_string_literal: true

# This migration comes from decidim_dataspace (originally 20250805133740)
class CreateContainers < ActiveRecord::Migration[7.0]
  def change
    create_table :dataspace_containers do |t|
      t.belongs_to :interoperable, null: false, foreign_key: { to_table: :dataspace_interoperables }
      t.belongs_to :parent, optional: true, index: true
      t.string :name
      t.string :description
    end
  end
end
