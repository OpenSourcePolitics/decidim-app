# frozen_string_literal: true
# This migration comes from decidim_guest_meeting_registration (originally 20240820021914)

class AddDisableNormalAccountToRegisterSettings < ActiveRecord::Migration[6.0]
  def change
    add_column :decidim_guest_meeting_registration_settings, :disable_account_confirmation, :boolean, default: false
  end
end
