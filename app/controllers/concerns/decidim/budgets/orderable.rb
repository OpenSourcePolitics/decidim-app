# frozen_string_literal: true

require "active_support/concern"

module Decidim
  module Budgets
    # Common logic to sorting resources
    module Orderable
      extend ActiveSupport::Concern

      included do
        include Decidim::Orderable

        private

        # Available orders based on enabled settings
        def available_orders
          @available_orders ||= [default_order] + possible_orders.excluding(default_order)
        end

        def possible_orders
          @possible_orders ||= begin
            available_orders = []
            available_orders << "random" if voting_open? || !votes_are_visible?
            available_orders << "most_voted" if votes_are_visible?
            available_orders += %w(alphabetical highest_cost lowest_cost)
            available_orders
          end
        end

        def default_order
          @default_order ||= fetch_default_order
        end

        def fetch_default_order
          default_order = current_settings.default_sort_order.presence || component_settings.default_sort_order
          return order_by_default if default_order == "default"

          possible_orders.include?(default_order) ? default_order : order_by_default
        end

        def order_by_default
          voting_open? || !votes_are_visible? ? "random" : "most_voted"
        end

        def votes_are_visible?
          current_settings.show_votes?
        end

        def reorder(projects)
          case order
          when "alphabetical"
            reorder_alphabetically(projects)
          when "highest_cost"
            reorder_by_highest_cost(projects)
          when "lowest_cost"
            reorder_by_lowest_cost(projects)
          when "most_voted"
            reorder_by_most_voted(projects)
          when "random"
            reorder_randomly(projects)
          else
            projects
          end
        end

        def reorder_alphabetically(projects)
          projects.ordered_ids(
            projects.sort_by { |project| project.title[I18n.locale.to_s] || "" }.map(&:id)
          )
        end

        def reorder_by_highest_cost(projects)
          projects.order(budget_amount: :desc)
        end

        def reorder_by_lowest_cost(projects)
          projects.order(budget_amount: :asc)
        end

        def reorder_by_most_voted(projects)
          return projects unless votes_are_visible?

          ids = projects.sort_by(&:confirmed_orders_count).map(&:id).reverse
          projects.ordered_ids(ids)
        end

        def reorder_randomly(projects)
          projects.order_randomly(random_seed)
        end
      end
    end
  end
end
