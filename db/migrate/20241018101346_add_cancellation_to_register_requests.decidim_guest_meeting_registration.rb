# frozen_string_literal: true
# This migration comes from decidim_guest_meeting_registration (originally 20240820021912)

class AddCancellationToRegisterRequests < ActiveRecord::Migration[6.0]
  def change
    add_column :decidim_guest_meeting_registration_registration_requests, :cancellation_token, :string, after: :name
  end
end
