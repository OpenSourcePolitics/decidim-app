namespace :db do
  task migrations_fix: :environment do
    eval(File.read(Rails.root.join('db/migration_fixes.rb')))
    puts "Migration fixes applied"
  end

  namespace :schema do
    desc "Dump schema migration table in a sql file named in db/schema_migrations.sql"
    task migrations_dump: :environment do
      database_name = Rails.configuration.database_configuration[Rails.env]['database']
      output = Rails.root.join('db/schema_migrations.sql')

      success = system("pg_dump -Fa -O -t schema_migrations '#{database_name}' > #{output}", exception: true)

      if success
        puts "Schema migration table dumped to #{output}"
      else
        puts "Failed to dump schema migration table to #{output}"
      end
    end

    task migrations_replace: :environment do
      database_name = Rails.configuration.database_configuration[Rails.env]['database']
      input = Rails.root.join('db/schema_migrations.sql')
      migrations_count = ActiveRecord::SchemaMigration.count

      drop = system("psql -q -d '#{database_name}' -c 'DROP TABLE schema_migrations'", exception: true)
      import = system("psql -q -d '#{database_name}' -f #{input}", exception: true)
      migrations_to_delete = ActiveRecord::SchemaMigration.all.map(&:version)[migrations_count..-1]
      ActiveRecord::SchemaMigration.where(version: migrations_to_delete).delete_all
      sequence = system("psql -q -d '#{database_name}' -c 'ALTER SEQUENCE versions_id_seq RESTART WITH #{migrations_count + 1}'", exception: true)

      if drop && import && sequence
        puts "Schema migration table replaced"
      else
        puts "Failed to replace schema migration table"
      end
    end
  end
end

Rake::Task['db:migrate'].enhance do
  at_exit do
    Rake::Task['db:schema:migrations_dump'].invoke
  end
end