# frozen_string_literal: true
# This migration comes from decidim_half_signup (originally 20230215093510)

class AddPhoneNumberToDecidimUser < ActiveRecord::Migration[6.1]
  def up
    add_column :decidim_users, :phone_number, :string, if_not_exists: true
    add_column :decidim_users, :phone_country, :string, if_not_exists: true
  end

  def down; end
end
