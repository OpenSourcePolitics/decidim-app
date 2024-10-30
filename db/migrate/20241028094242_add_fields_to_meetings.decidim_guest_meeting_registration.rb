# frozen_string_literal: true
# This migration comes from decidim_guest_meeting_registration (originally 20240926224810)

class AddFieldsToMeetings < ActiveRecord::Migration[6.0]
  def change
    add_column :decidim_meetings_meetings, :enable_guest_registration, :boolean, default: false
    add_column :decidim_meetings_meetings, :enable_registration_confirmation, :boolean, default: false
    add_column :decidim_meetings_meetings, :enable_cancellation, :boolean, default: false
    add_column :decidim_meetings_meetings, :disable_account_confirmation, :boolean, default: false
  end
end