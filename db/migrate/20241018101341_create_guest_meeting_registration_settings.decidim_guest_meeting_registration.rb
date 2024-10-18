# frozen_string_literal: true
# This migration comes from decidim_guest_meeting_registration (originally 20240820021907)

class CreateGuestMeetingRegistrationSettings < ActiveRecord::Migration[6.0]
  def change
    create_table :decidim_guest_meeting_registration_settings do |t|
      t.boolean :enable_guest_registration, default: false
      t.references :decidim_organization, foreign_key: true, index: { name: :index_guest_meeting_registration_settings_on_organization_id }

      t.timestamps
    end
  end
end
