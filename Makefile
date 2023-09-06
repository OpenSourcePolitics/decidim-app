# Starts with production configuration
local-prod:
	docker-compose up -d

# Starts with development configuration
# TODO: Fix seeds for local-dev make command
local-dev:
	docker-compose -f docker-compose.dev.yml up -d
	@make create-database
	@make run-migrations
	#@make create-seeds

# Stops containers and remove volumes
teardown:
	docker-compose down -v --rmi all

# Starts containers and restore dump
local-restore:
	@make create-database
	@make -i restore-dump
	@make run-migrations
	@make start

# Create database
create-database:
	docker-compose run app bundle exec rails db:create
# Run migrations
run-migrations:
	docker-compose run app bundle exec rails db:migrate
# Create seeds
create-seeds:
	docker-compose exec -e RAILS_ENV=development app /bin/bash -c '/usr/local/bundle/bin/bundle exec rake db:seed'
# Restore dump
restore-dump:
	bundle exec rake restore_dump
