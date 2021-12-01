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
docker-create-database:
	docker-compose run app bundle exec rails db:create
docker-run-migrations:
	docker-compose run app bundle exec rails db:migrate
docker-create-seeds:
	docker-compose run app DECIDIM_HOST=0.0.0.0 bundle exec rails db:seed

# Database commands 
docker-copy-dump: 
	docker cp "LOCAL_PATH_TO_DUMP" decidim-app_database_1:"/tmp/CONTAINER_DUMP"
docker-restore-dump:
	@make docker-copy-dump
	docker exec -it decidim-app_database_1 su postgres -c "pg_restore -c -O -v -d osp_app /tmp/CONTAINER_DUMP"

# Start commands seperated by context
start-dumped-decidim:
	@make docker-create-database
	@make docker-restore-dump
	@make docker-run-migrations
	docker-compose up
start-seeded-decidim:
	@make docker-create-database
	@make docker-run-migrations
	@make docker-create-seeds
	docker-compose up
start-clean-decidim:
	@make docker-create-database
	@make docker-run-migrations
	docker-compose up

# Utils commands
docker-rails-console:
	docker exec -it decidim-app_app_1 rails c

# Stop and delete commands
docker-stop:
	docker-compose down
docker-delete:
	@make docker-stop
	docker compose down && docker volume prune
