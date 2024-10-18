# frozen_string_literal: true
# This migration comes from decidim_guest_meeting_registration (originally 20240820021910)

class AddConfirmationToRegisterRequests < ActiveRecord::Migration[6.0]
  def change
    add_column :decidim_guest_meeting_registration_registration_requests, :confirmation_token, :string, after: :name
    add_column :decidim_guest_meeting_registration_registration_requests, :confirmed_at, :datetime, after: :confirmation_token
  end
end
