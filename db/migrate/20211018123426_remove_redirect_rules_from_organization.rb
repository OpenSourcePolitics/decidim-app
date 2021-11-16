# frozen_string_literal: true

class RemoveRedirectRulesFromOrganization < ActiveRecord::Migration[5.2]
  def change
    drop_table :redirect_rules, if_exists: true
  end
end
