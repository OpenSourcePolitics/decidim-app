# frozen_string_literal: true

# This migration comes from decidim (originally 20190523210408)

class AddDeeplTranslatorToOrganization < ActiveRecord::Migration[5.2]
  def change
    add_column :decidim_organizations, :deepl_api_key, :string
  end
end
