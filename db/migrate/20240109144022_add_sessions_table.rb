class AddSessionsTable < ActiveRecord::Migration[6.1]
  def up
    create_table :sessions do |t|
      t.string :session_id, null: false
      t.text :data
      t.timestamps
    end

    add_index :sessions, :session_id, unique: true
    add_index :sessions, :updated_at
  end

  def down
    drop_table :sessions

    remove_index :sessions, :session_id
    remove_index :sessions, :updated_at
  end
end
