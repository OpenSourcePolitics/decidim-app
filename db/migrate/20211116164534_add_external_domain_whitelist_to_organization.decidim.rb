# frozen_string_literal: true

# This migration comes from decidim (originally 20210210114657)

class AddExternalDomainWhitelistToOrganization < ActiveRecord::Migration[5.2]
  def change
    add_column :decidim_organizations, :external_domain_whitelist, :string, array: true, default: []

    reversible do |direction|
      direction.up do
        Decidim::Organization.update_all("external_domain_whitelist = ARRAY['decidim.org', 'github.com']")
      end
    end
  end
end
