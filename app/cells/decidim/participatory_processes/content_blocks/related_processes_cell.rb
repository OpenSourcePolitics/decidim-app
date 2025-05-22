# frozen_string_literal: true

module Decidim
  module ParticipatoryProcesses
    module ContentBlocks
      class RelatedProcessesCell < Decidim::ContentBlocks::BaseCell
        def show
          render if total_count.positive?
        end

        def related_processes
          processes = resource
                      .linked_participatory_space_resources(:participatory_processes, link_name)
                      .published
                      .all

          # Change the order of the processes if the setting is enabled
          # and use the new method "sort_processes_from"
          @related_processes = if Rails.application.secrets.dig(:decidim, :participatory_processes, :sort_by_date) == false
                                 processes
                               else
                                 sort_processes_from(processes)
                               end
        end

        # Addition of the new method that sorts the processes in the assemblies
        def sort_processes_from(processes)
          actives_processes ||= processes.select(&:active?)
          actives = actives_processes.reject { |process| process.end_date.nil? }.sort_by(&:end_date) + processes_without_end_date(actives_processes)
          pasts = processes.select(&:past?).sort_by(&:end_date).reverse
          upcomings = processes.select(&:upcoming?).sort_by(&:start_date)
          (actives + upcomings + pasts)
        end

        def processes_without_end_date(processes)
          processes.select { |process| process.end_date.nil? }
        end

        def filtered_processes
          return related_processes unless limit?

          # Important change : Replace the .limit method with the take method
          # to avoid the error "undefined method 'limit'" for the related_processes
          # if they were sorted using the "sort_processes_from" method (that returns an array and not a relation)
          # Please note that the "take" method still does work with relations
          related_processes.take(limit)
        end

        def total_count
          related_processes.size
        end

        private

        def link_name
          resource.is_a?(Decidim::ParticipatoryProcess) ? "related_processes" : "included_participatory_processes"
        end

        def resource
          options[:resource] || super
        end

        def limit
          @limit ||= model.settings.try(:max_results)
        end

        def limit?
          limit.to_i.positive?
        end

        def title
          t("related_processes", scope: "decidim.participatory_processes.show")
        end
      end
    end
  end
end
