namespace :db do
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
  end
end

Rake::Task['db:migrate'].enhance do
  at_exit do
    Rake::Task['db:schema:migrations_dump'].invoke
  end
end