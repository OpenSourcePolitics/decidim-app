#### Terraform | Scaleway provider
init-scw:
	terraform -chdir=deploy/providers/scaleway init

plan-scw:
	@make init-scw
	terraform -chdir=deploy/providers/scaleway plan	
	
deploy-scw:
	@make init-scw
	terraform -chdir=deploy/providers/scaleway apply

destroy-scw:
	terraform -chdir=deploy/providers/scaleway destroy

### Docker usage

# Docker images commands

REGISTRY := rg.fr-par.scw.cloud
NAMESPACE := decidim-app
VERSION := latest
IMAGE_NAME := decidim-app
TAG := $(REGISTRY)/$(NAMESPACE)/$(IMAGE_NAME):$(VERSION)

login:
	docker login $(REGISTRY) -u nologin -p $(SCW_SECRET_TOKEN)

build-classic:
	docker buildx build -t $(IMAGE_NAME):$(VERSION) . --platform linux/amd64
build-scw:
	docker build -t $(TAG) .
push:
	@make build-scw
	@make login
	docker push $(TAG)
pull:
	@make build-scw
	docker pull $(TAG)

# Bundle commands
create-database:
	docker-compose run app bundle exec rails db:create
run-migrations:
	docker-compose run app bundle exec rails db:migrate
create-seeds:
	docker-compose exec -e RAILS_ENV=development app /bin/bash -c '/usr/local/bundle/bin/bundle exec rake db:seed'

# Database commands 
restore-dump:
	bundle exec rake restore_dump 

# Start commands seperated by context
start:
	docker-compose up

start-dumped-decidim:
	@make create-database
	@make -i restore-dump
	@make run-migrations
	@make start
start-seeded-decidim:
	@make create-database
	@make run-migrations
	@make create-seeds
	@make start
start-clean-decidim:
	@make create-database
	@make run-migrations
	@make start

teardown:
	docker-compose down -v --rmi all

# TODO: Fix seeds for local-dev make command
local-dev:
	docker-compose -f docker-compose.dev.yml up -d
	@make create-database
	@make run-migrations
	#@make create-seeds
