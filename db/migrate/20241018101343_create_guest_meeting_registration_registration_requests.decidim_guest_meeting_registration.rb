# frozen_string_literal: true
# This migration comes from decidim_guest_meeting_registration (originally 20240820021909)

class CreateGuestMeetingRegistrationRegistrationRequests < ActiveRecord::Migration[6.0]
  def change
    create_table :decidim_guest_meeting_registration_registration_requests do |t|
      t.references :decidim_organization, foreign_key: true, index: { name: :index_guest_meeting_registration_rr_on_organization_id }
      t.references :decidim_meetings_meetings, foreign_key: true, index: { name: :index_guest_meeting_registration_mm_on_organization_id }
      t.integer :decidim_user_id, index: { name: :index_guest_meeting_registration_uid_on_organization_id }

      t.jsonb :form_data
      t.string :email, null: false
      t.string :name

      t.timestamps
    end
  end
end
