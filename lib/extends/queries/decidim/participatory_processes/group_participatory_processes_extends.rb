# frozen_string_literal: true

module GroupParticipatoryProcessesExtends
  def query
    Decidim::ParticipatoryProcess.where(participatory_process_group: @group).order(weight: :asc)
  end
end

Decidim::ParticipatoryProcesses::GroupParticipatoryProcesses.class_eval do
  prepend(GroupParticipatoryProcessesExtends)
end
