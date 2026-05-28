# frozen_string_literal: true
# This migration comes from decidim (originally 20180206143340)
class FixReferenceForAllResources < ActiveRecord::Migration[5.1]
  def up
    models = ActiveRecord::Base.descendants.select { |c| c.included_modules.include?(Decidim::HasReference) }
    models.each do |model|
      next unless model.table_exists?

      begin
        model.unscoped.find_each(&:touch)
      rescue StandardError => e
        Rails.logger.warn("FixReferenceForAllResources: skipping #{model.name} - #{e.message}")
      end
    end
  end
  def down; end
end
