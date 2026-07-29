image_name = decidim-app
image_tag = 3.4.0

TARGET_ARCH := $(shell [ "$(shell uname -m)" = "arm64" ] && echo "arm64" || echo "amd64")

COMPOSE_PROD := docker compose -f docker-compose.yml -f docker-compose.prod.yml

.DEFAULT_GOAL := help

run: up ## Build and start the application
	@make setup-seeds

up: build ## Start containers and setup database
	docker compose up -d
	@make setup-database

build:
	@echo "Building for $(TARGET_ARCH)..."
	docker build \
		--build-arg TARGETARCH=$(TARGET_ARCH) \
		--build-arg DOCKER_IMAGE_NAME=$(image_name) \
		--build-arg DOCKER_IMAGE_TAG=$(image_tag) \
		--build-arg DOCKER_IMAGE=rg.fr-par.scw.cloud/decidim-app/$(image_name):$(image_tag) \
		-t "$(image_name):$(image_tag)" .

teardown: ## Stop containers and remove volumes
	docker compose down -v --rmi all

create-database: ## Create database
	@docker compose exec -T app /bin/bash -c 'DISABLE_DATABASE_ENVIRONMENT_CHECK=1 bundle exec rake db:create' > /dev/null 2>&1

setup-database: create-database ## Create and migrate database
	@docker compose exec -T app /bin/bash -c 'DISABLE_DATABASE_ENVIRONMENT_CHECK=1 bundle exec rake db:migrate migrate:db:force' > /dev/null 2>&1

setup-seeds: ## Create seeds only if database is empty
	@echo "Checking if database needs seeding..."
	@if docker compose exec -T app /bin/bash -c 'DISABLE_DATABASE_ENVIRONMENT_CHECK=1 bundle exec rails runner "exit(Decidim::Organization.count == 0 ? 0 : 1)"' > /dev/null 2>&1; then \
		echo "Database is empty, creating seeds..."; \
		make create-seeds; \
	else \
		echo "Database already has data, skipping seeds."; \
		echo "Application started at https://localhost:3000"; \
	fi

create-seeds: ## DESTRUCTIVE: Drop all data and create seeds
	@echo "WARNING: This will destroy all existing data!"
	@echo "Creating seeds... You can still access the app at https://localhost:3000 and it will generate seeds in background."
	@start=$$(date +%s); \
	docker compose exec -T app /bin/bash -c 'DISABLE_DATABASE_ENVIRONMENT_CHECK=1 RAILS_LOG_LEVEL=error bundle exec rake db:schema:load db:seed' > /dev/null 2>&1; \
	end=$$(date +%s); \
	duration=$$((end - start)); \
	echo "Seeds created successfully in $${duration}s"

restore-dump: ## Restore database from dump
	bundle exec rake restore_dump

shell: ## Open a bash shell in the app container
	docker compose exec app /bin/bash

restart: ## Restart containers
	docker compose up -d

status: ## Show containers status
	docker compose ps

logs: ## Show app logs
	docker compose logs app

external: ## Update host for external access (requires IP=x.x.x.x)
	@if [ -z "$(IP)" ]; then \
		echo "Pass IP as follow : make external IP=192.168.64.1"; \
		echo "You can discover your IP as follow : \n > ifconfig | grep netmask | grep -v 127.0.0.1 | awk '{print \$$2}' | tail -n1"; \
		exit 1; \
	fi
	@docker compose exec -T app /bin/bash -c 'DISABLE_DATABASE_ENVIRONMENT_CHECK=1 bundle exec rails runner "puts Decidim::Organization.first.update(host: \"$(IP)\")"' > /dev/null 2>&1
	@echo "Decidim organization host updated to $(IP)"
	@echo "App is now accessible at https://$(IP):3000"

rebuild: ## Rebuild everything from scratch
	docker compose down
	@docker volume rm decidim-app_shared-volume 2>/dev/null || true
	@make up

prod-init-storage: ## Prod: fix storage volume permissions (run once before first start)
	$(COMPOSE_PROD) up init_storage

prod-create-db: ## Prod: create an empty database, no schema (run before first restore, not before db:migrate)
	$(COMPOSE_PROD) run --rm -e RAILS_ENV=production db_migrate /bin/bash -c "DISABLE_DATABASE_ENVIRONMENT_CHECK=1 bundle exec rake db:create"

prod-migrate: ## Prod: run pending DB migrations (run on every deploy, or after a restore)
	$(COMPOSE_PROD) run --rm db_migrate

prod-up: ## Prod: start database/redis/memcached/sidekiq/app
	$(COMPOSE_PROD) up -d database redis memcached sidekiq app

prod-deploy: prod-init-storage prod-migrate prod-up ## Prod: full deploy sequence (init storage, migrate, start)

prod-restart: ## Prod: restart app and sidekiq only (no migration)
	$(COMPOSE_PROD) up -d --no-deps sidekiq app

prod-status: ## Prod: show containers status
	$(COMPOSE_PROD) ps

prod-logs: ## Prod: show app logs
	$(COMPOSE_PROD) logs -f app

prod-shell: ## Prod: open a bash shell in the app container
	$(COMPOSE_PROD) exec app /bin/bash

prod-console: ## Prod: open a Rails console
	$(COMPOSE_PROD) exec app bundle exec rails console

prod-down: ## Prod: stop containers (keeps volumes)
	$(COMPOSE_PROD) down

prod-restore-dump: ## Prod: restore a PostgreSQL dump (requires DUMP=/path/to/dump.pgcustom, DB=database_name)
	@if [ -z "$(DUMP)" ] || [ -z "$(DB)" ]; then \
		echo "Usage: make prod-restore-dump DUMP=/path/to/dump.pgcustom DB=database_name"; \
		exit 1; \
	fi
	$(COMPOSE_PROD) cp $(DUMP) database:/tmp/dump.pgcustom
	$(COMPOSE_PROD) exec database pg_restore -U postgres -d $(DB) --no-owner /tmp/dump.pgcustom

prod-restore-storage: ## Prod: restore Active Storage files (requires SRC=/path/to/storage)
	@if [ -z "$(SRC)" ]; then \
		echo "Usage: make prod-restore-storage SRC=/path/to/storage"; \
		exit 1; \
	fi
	docker run --rm -v decidim-app_storage-data:/dest -v $(SRC):/src alpine sh -c "cp -a /src/. /dest/"

prod-config: ## Prod: print merged compose config for review
	$(COMPOSE_PROD) config

tls-cert: ## Generate TLS certificate
	@mkdir -p $(HOME)/.decidim/tls-certificate
	@openssl req -new -newkey rsa:4096 -days 365 -nodes -x509 \
		-subj "/C=FR/ST=France/L=Paris/O=decidim/CN=decidim.eu" \
		-addext "subjectAltName = DNS:localhost, DNS:minio" \
		-keyout $(HOME)/.decidim/tls-certificate/key.pem \
		-out $(HOME)/.decidim/tls-certificate/cert.pem 2>/dev/null

help: ## Show available commands
	@echo "Available commands:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

.PHONY: help run up build teardown create-database setup-database create-seeds restore-dump shell restart status logs external rebuild tls-cert \
	prod-init-storage prod-create-db prod-migrate prod-up prod-deploy prod-restart prod-status prod-logs prod-shell prod-console prod-down \
	prod-restore-dump prod-restore-storage prod-config