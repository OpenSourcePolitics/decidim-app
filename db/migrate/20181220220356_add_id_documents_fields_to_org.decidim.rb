# frozen_string_literal: true

# This migration comes from decidim (originally 20181126145142)

class AddIdDocumentsFieldsToOrg < ActiveRecord::Migration[5.2]
  def change
    add_column :decidim_organizations, :id_documents_methods, :string, array: true, default: ["online"]
    add_column :decidim_organizations, :id_documents_explanation_text, :jsonb, default: {}

    Decidim::Organization.reset_column_information
    Decidim::Organization.update_all(id_documents_methods: ["online"])
  end
end
