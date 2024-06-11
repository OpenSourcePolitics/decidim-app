run: up
	@make create-seeds

up:
	docker build . -f Dockerfile.local -t decidim-app-app:latest
	docker build . -f Dockerfile.local -t decidim-app-sidekiq:latest
	docker-compose -f docker-compose.local.yml up -d
	@make setup-database

# Stops containers and remove volumes
teardown:
	docker-compose -f docker-compose.local.yml down -v --rmi all

create-database:
	docker-compose -f docker-compose.local.yml exec app /bin/bash -c 'DISABLE_DATABASE_ENVIRONMENT_CHECK=1 /usr/local/bundle/bin/bundle exec rake db:create'

setup-database: create-database
	docker-compose -f docker-compose.local.yml exec app /bin/bash -c 'DISABLE_DATABASE_ENVIRONMENT_CHECK=1 /usr/local/bundle/bin/bundle exec rake db:migrate'

# Create seeds
create-seeds:
	docker-compose -f docker-compose.local.yml exec app /bin/bash -c 'DISABLE_DATABASE_ENVIRONMENT_CHECK=1 /usr/local/bundle/bin/bundle exec rake db:schema:load db:seed'

# Restore dump
restore-dump:
	bundle exec rake restore_dump

shell:
	docker-compose -f docker-compose.local.yml exec app /bin/bash

restart:
	docker-compose -f docker-compose.local.yml up -d

status:
	docker-compose -f docker-compose.local.yml ps

logs:
	docker-compose -f docker-compose.local.yml logs app

rebuild:
	docker-compose -f docker-compose.local.yml up --build -d