# frozen_string_literal: true
# This migration comes from decidim_guest_meeting_registration (originally 20240820021911)

class AddCancellationSettings < ActiveRecord::Migration[6.0]
  def change
    add_column :decidim_guest_meeting_registration_settings, :enable_cancellation, :boolean, default: false, after: :enable_guest_registration
  end
end
