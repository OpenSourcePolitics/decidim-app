image_name = decidim-app
image_tag = 3.4.0

TARGET_ARCH := $(shell [ "$(shell uname -m)" = "arm64" ] && echo "arm64" || echo "amd64")

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

ruby-image: ## Build the patched Ruby base image locally (this host's arch)
	PLATFORM=linux/$(TARGET_ARCH) ./ruby-patched/build.sh

ruby-image-push: ## Build and push the patched Ruby base image (amd64; needs docker login)
	PUSH=1 PLATFORM=linux/amd64 ./ruby-patched/build.sh

ruby-image-pin: ## Build, push (amd64) and pin the pushed digest into the Dockerfile
	PUSH=1 PIN=1 PLATFORM=linux/amd64 ./ruby-patched/build.sh

hooks: ## Install the repo git hooks (sets core.hooksPath to .githooks)
	git config core.hooksPath .githooks
	@echo "Git hooks installed from .githooks. Bypass a hook with: git commit --no-verify"

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

create-seeds: ## ⚠️  DESTRUCTIVE: Drop all data and create seeds
	@echo "⚠️  WARNING: This will destroy all existing data!"
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

.PHONY: help run up build ruby-image ruby-image-push ruby-image-pin hooks teardown create-database setup-database create-seeds restore-dump shell restart status logs external rebuild tls-cert
