# This migration comes from decidim_admin_multi_factor (originally 20241126021907)

# frozen_string_literal: true

class CreateDecidimAdminMultiFactorSettings < ActiveRecord::Migration[6.0]
  def change
    create_table :decidim_admin_multi_factor_settings do |t|
      t.boolean :enable_multifactor, default: false
      t.boolean :email, default: false
      t.boolean :sms, default: false
      t.boolean :webauthn, default: false
      t.references :decidim_organization, foreign_key: true, index: { name: :index_decidim_admin_multi_factor_settings_on_organization_id }

      t.timestamps
    end
  end
end
