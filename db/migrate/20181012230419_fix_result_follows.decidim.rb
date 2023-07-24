# frozen_string_literal: true

# This migration comes from decidim (originally 20180706111847)

class FixResultFollows < ActiveRecord::Migration[5.2]
  def change
    Decidim::Follow.where(decidim_followable_type: "Decidim::Results::Result").update_all(decidim_followable_type: "Decidim::Accountability::Result")
  end
end
