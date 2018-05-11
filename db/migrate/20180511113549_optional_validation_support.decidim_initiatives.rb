# This migration comes from decidim_initiatives (originally 20171023141639)
# frozen_string_literal: true

class OptionalValidationSupport < ActiveRecord::Migration[5.1]
  def change
    add_column :decidim_initiatives_types,
               :requires_validation, :boolean, null: false, default: true
  end
end
