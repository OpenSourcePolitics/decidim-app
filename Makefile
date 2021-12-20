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
	docker build -t $(IMAGE_NAME):$(VERSION) .
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
	docker-compose run app bundle exec rails db:seed

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

# Utils commands
rails-console:
	docker exec -it decidim-app_app_1 rails c
connect-app:
	docker exec -it decidim-app_app_1 bash

# Stop and delete commands
stop:
	docker-compose down
delete:
	@make stop
	docker volume prune

redis-setup:
	helm install redis-cluster bitnami/redis \
	  --set auth.enabled=false \
      --set cluster.slaveCount=3 \
      --set securityContext.enabled=true \
      --set securityContext.fsGroup=2000 \
      --set securityContext.runAsUser=1000 \
      --set volumePermissions.enabled=true \
      --set master.persistence.enabled=true \
      --set master.persistence.path=/data \
      --set master.persistence.size=8Gi \
      --set master.persistence.storageClass="scw-bssd-retain" \
      --set slave.persistence.enabled=true \
      --set slave.persistence.path=/data \
      --set slave.persistence.size=8Gi \
      --set slave.persistence.storageClass="scw-bssd-retain"