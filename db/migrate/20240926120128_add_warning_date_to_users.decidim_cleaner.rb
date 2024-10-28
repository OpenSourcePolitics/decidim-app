# frozen_string_literal: true
# This migration comes from decidim_cleaner (originally 20230328094652)

class AddWarningDateToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :decidim_users, :warning_date, :datetime
  end
end
