# frozen_string_literal: true
# This migration comes from decidim_half_signup (originally 20230215093510)

class AddPhoneNumberToDecidimUser < ActiveRecord::Migration[6.1]
  def change
    add_column :decidim_users, :phone_number, :string
    add_column :decidim_users, :phone_country, :string
  end
end
