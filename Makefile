run: up
	@make create-seeds

up: generate-certificate
	docker-compose -f docker-compose.local.yml up --build -d
	@make setup-database

certificate:
	mkdir -p -- ./certificate-https-local

generate-certificate: certificate
	@if [ ! -f "./certificate-https-local/cert.pem" ]; then \
		openssl req -new -newkey rsa:4096 -days 365 -nodes -x509 -subj "/C=FR/ST=France/L=Paris/O=OpenSourcePolitics/CN=opensourcepolitics.eu" -keyout ./certificate-https-local/key.pem -out ./certificate-https-local/cert.pem; \
	fi

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