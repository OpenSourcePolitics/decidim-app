# frozen_string_literal: true

# This migration comes from decidim_half_signup (originally 20230214091207)

class CreateAuthSettings < ActiveRecord::Migration[6.0]
  def change
    create_table :decidim_half_signup_auth_settings do |t|
      t.boolean :enable_partial_sms_signup, default: false
      t.boolean :enable_partial_email_signup, default: false
      t.string :slug
      t.references :decidim_organization, foreign_key: true, index: { name: :index_half_signup_auth_settings_on_organization_id }

      t.timestamps
    end
  end
end
