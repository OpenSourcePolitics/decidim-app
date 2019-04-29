# frozen_string_literal: true
# This migration comes from decidim_participatory_processes (originally 20180928085945)

class AddActionBtnTextFieldToSteps < ActiveRecord::Migration[5.2]
  def change
    add_column :decidim_participatory_process_steps, :action_btn_text, :jsonb
  end
end
