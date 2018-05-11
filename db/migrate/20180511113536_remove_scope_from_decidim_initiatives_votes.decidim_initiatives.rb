# This migration comes from decidim_initiatives (originally 20170928160912)
# frozen_string_literal: true

class RemoveScopeFromDecidimInitiativesVotes < ActiveRecord::Migration[5.1]
  def change
    remove_column :decidim_initiatives_votes, :scope, :integer
  end
end
