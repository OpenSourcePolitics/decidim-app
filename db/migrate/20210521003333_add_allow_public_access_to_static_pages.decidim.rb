# frozen_string_literal: true

# This migration comes from decidim (originally 20201128130723)

class AddAllowPublicAccessToStaticPages < ActiveRecord::Migration[5.2]
  def change
    add_column :decidim_static_pages, :allow_public_access, :boolean, null: false, default: false

    reversible do |direction|
      direction.up do
        Decidim::StaticPage.where(slug: "terms-and-conditions").update_all(
          allow_public_access: true
        )
      end
    end
  end
end
