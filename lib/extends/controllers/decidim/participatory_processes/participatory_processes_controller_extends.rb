# frozen_string_literal: true

require "active_support/concern"

module ParticipatoryProcessesControllerExtends
  extend ActiveSupport::Concern
  included do
    def participatory_processes
      @participatory_processes ||= filtered_processes.groupless.includes(attachments: :file_attachment)
      return @participatory_processes if Decidim::Env.new("DECIDIM_PARTICIPATORY_PROCESSES_SORT_BY_DATE", true).to_boolean_string == "false"

      custom_sort(search.with_date)
    end

    def custom_sort(date)
      case date
      when "active"
        @participatory_processes.reject { |process| process.end_date.nil? }.sort_by(&:end_date) + processes_without_end_date(@participatory_processes)
      when "past"
        @participatory_processes.sort_by(&:end_date).reverse
      when "upcoming"
        @participatory_processes.sort_by(&:start_date)
      when "all"
        @participatory_processes = sort_all_processes
      else
        @participatory_processes
      end
    end

    def sort_all_processes
      @actives_processes ||= @participatory_processes.select(&:active?)
      actives = @actives_processes.reject { |process| process.end_date.nil? }.sort_by(&:end_date) + processes_without_end_date(@actives_processes)
      pasts = @participatory_processes.select(&:past?).sort_by(&:end_date).reverse
      upcomings = @participatory_processes.select(&:upcoming?).sort_by(&:start_date)
      (actives + upcomings + pasts)
    end

    def processes_without_end_date(processes)
      processes.select { |process| process.end_date.nil? }
    end
  end
end

Decidim::ParticipatoryProcesses::ParticipatoryProcessesController.include(ParticipatoryProcessesControllerExtends)
