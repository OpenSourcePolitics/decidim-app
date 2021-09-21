# frozen_string_literal: true

# This migration comes from decidim_calendar (originally 20190312132654)

class CreateDecidimCalendarExternalEvents < ActiveRecord::Migration[5.2]
  def change
    create_table :decidim_calendar_external_events do |t|
      t.jsonb :title, null: false
      t.datetime :start_at, null: false
      t.datetime :end_at, null: false
      t.string :url
      t.integer :decidim_author_id, null: false
      t.string :decidim_author_type
      t.integer :decidim_organization_id, null: false

      t.index :decidim_author_id, name: :decidim_calendar_external_event_author
      t.index :decidim_organization_id, name: :decidim_calendar_external_event_organization
    end
  end
end
