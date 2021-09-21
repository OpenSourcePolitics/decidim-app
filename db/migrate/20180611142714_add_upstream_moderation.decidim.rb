# frozen_string_literal: true

# This migration comes from decidim (originally 20180108155030)
class AddUpstreamModeration < ActiveRecord::Migration[5.1]
  def change
    add_column :decidim_moderations, :upstream_moderation, :string, default: "unmoderate"
  end
end
