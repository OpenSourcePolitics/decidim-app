class DeleteDecidimParticipativeActionsCompletedTable < ActiveRecord::Migration[6.1]
  def change
    drop_table :participative_actions_completed
  end
end
