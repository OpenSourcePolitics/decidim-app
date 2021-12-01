#### Scaleway provider
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
start-dumped-decidim:
	@make create-database
	@make -i restore-dump
	@make run-migrations
	docker-compose up
start-seeded-decidim:
	@make create-database
	@make run-migrations
	@make create-seeds
	docker-compose up
start-clean-decidim:
	@make create-database
	@make run-migrations
	docker-compose up

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
	docker compose down && docker volume prune
