# This migration comes from decidim_emitter (originally 20240417082337)
class AddEmitterToDecidimParticipatoryProcess < ActiveRecord::Migration[6.1]
  def up
    # Ensure that the column is a string and check if it exists
    add_column :decidim_participatory_processes, :emitter, :string, if_not_exists: true
    change_column :decidim_participatory_processes, :emitter, :string

    add_column :decidim_participatory_processes, :emitter_name, :text, if_not_exists: true
  end

  def down
    remove_column :decidim_participatory_processes, :emitter_name, if_exists: true
  end
end
