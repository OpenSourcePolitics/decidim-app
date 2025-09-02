# frozen_string_literal: true

# This migration comes from decidim_decidim_awesome (originally 20210628150825)

class ChangeAwesomeConfigVarType < ActiveRecord::Migration[5.2]
  def change
    return unless defined?(Decidim::DecidimAwesome::AwesomeConfig)

    change_column :decidim_awesome_config, :var, :string, if_not_exists: true

    Decidim::DecidimAwesome::AwesomeConfig.find_each do |config|
      config.var.gsub!('"', "")
      config.save!
    end
  end
end
