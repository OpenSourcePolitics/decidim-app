# Migration fixes

Executes the following fixes in a rails console

## ERROR:  relation "redirect_rules" does not exists
```ruby
unless ActiveRecord::Base.connection.table_exists?(:redirect_rules)
  ActiveRecord::Base.connection.create_table :redirect_rules do |t|
    t.string :source, null: false
    t.boolean :source_is_regex, null: false, default: false
    t.boolean :source_is_case_sensitive, null: false, default: false
    t.string :destination, null: false
    t.boolean :active, default: false
    t.timestamps
  end
  ActiveRecord::Base.connection.add_index :redirect_rules, :source
  ActiveRecord::Base.connection.add_index :redirect_rules, :active
  ActiveRecord::Base.connection.add_index :redirect_rules, :source_is_regex
  ActiveRecord::Base.connection.add_index :redirect_rules, :source_is_case_sensitive
end
```
