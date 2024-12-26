# frozen_string_literal: true

# The component budgets already exists, we want to add a new settings to it to allow the user to configure the default order

POSSIBLE_SORT_ORDERS = %w(default random most_voted alphabetical highest_cost lowest_cost).freeze

Decidim.component_registry.find(:budgets).settings(:global) do |settings|
  settings.attribute :default_sort_order, type: :select, default: "default", choices: -> { POSSIBLE_SORT_ORDERS }
end

Decidim.component_registry.find(:budgets).settings(:step) do |settings|
  settings.attribute :default_sort_order, type: :select, include_blank: true, choices: -> { POSSIBLE_SORT_ORDERS }
end
