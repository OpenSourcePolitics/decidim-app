# Starts with production configuration
local-prod:
	docker-compose up -d

# Starts with development configuration
# TODO: Fix seeds for local-dev make command
run:
	#@make -i teardown
	@make generate-certificate
	docker-compose -f docker-compose.local.yml up -d --build
	@make create-database
	@make run-migrations
	@make create-seeds

certificate:
	mkdir -p -- ./certificate-https-local

generate-certificate: certificate
	@if [ ! -f "./certificate-https-local/cert.pem" ]; then \
		openssl req -new -newkey rsa:4096 -days 365 -nodes -x509 -subj "/C=FR/ST=France/L=Paris/O=OpenSourcePolitics/CN=opensourcepolitics.eu" -keyout ./certificate-https-local/key.pem -out ./certificate-https-local/cert.pem; \
	fi

# Stops containers and remove volumes
teardown:
	docker-compose down --rmi all

# Starts containers and restore dump
local-restore:
	@make create-database
	@make -i restore-dump
	@make run-migrations
	@make start
	@make create-seeds

# Create database
create-database:
	docker-compose run app bundle exec rails db:create
# Run migrations
run-migrations:
	docker-compose run app bundle exec rails db:migrate
# Create seeds
create-seeds:
	docker-compose exec app /bin/bash -c 'DISABLE_DATABASE_ENVIRONMENT_CHECK=1 /usr/local/bundle/bin/bundle exec rake db:schema:load db:seed'
# Restore dump
restore-dump:
	bundle exec rake restore_dump
