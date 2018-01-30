# This migration comes from decidim_participations (originally 20170612101809)
# frozen_string_literal: true

class MigrateParticipationsCategory < ActiveRecord::Migration[5.1]
  def change
    # Create categorizations ensuring database integrity
    execute('
      INSERT INTO decidim_categorizations(decidim_category_id, categorizable_id, categorizable_type, created_at, updated_at)
        SELECT decidim_category_id, decidim_participations_participations.id, \'Decidim::Participations::Participation\', NOW(), NOW()
        FROM decidim_participations_participations
        INNER JOIN decidim_categories ON decidim_categories.id = decidim_participations_participations.decidim_category_id
    ')
    # Remove unused column
    remove_column :decidim_participations_participations, :decidim_category_id
  end
end
