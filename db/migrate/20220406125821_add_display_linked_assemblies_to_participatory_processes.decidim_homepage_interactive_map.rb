# frozen_string_literal: true
# This migration comes from decidim_homepage_interactive_map (originally 20201113100047)

class AddDisplayLinkedAssembliesToParticipatoryProcesses < ActiveRecord::Migration[5.2]
  def change
    add_column :decidim_participatory_processes, :display_linked_assemblies, :boolean, default: false
  end
end
