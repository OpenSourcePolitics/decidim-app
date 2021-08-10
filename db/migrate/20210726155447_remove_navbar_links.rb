class RemoveNavbarLinks < ActiveRecord::Migration[5.2]
    def down
      drop_table :decidim_navbar_links
    end
  end
