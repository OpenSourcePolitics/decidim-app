# frozen_string_literal: true
# This migration comes from decidim_guest_meeting_registration (originally 20240820021913)

class AddSessionTokenToRegisterRequests < ActiveRecord::Migration[6.0]
  def change
    add_column :decidim_guest_meeting_registration_registration_requests, :session_token, :string, after: :name, unique: true
  end
end
