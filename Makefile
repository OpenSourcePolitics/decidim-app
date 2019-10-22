migration:
	docker-compose run app "rails db:migrate"

upgrade:
	docker-compose run app "rake decidim:upgrade"

create:
	docker-compose run app "rake db:create"

up:
	docker-compose up

prod:
	docker-compose -f docker-compose.prod.yml up

build:
	docker-compose build --compress --parallel

drop:
	docker-compose run app "rake db:drop"

setup:
	docker-compose run app "rake db:create db:migrate"

seed:
	docker-compose run app "SEED=true rake db:seed"

precompile:
	docker-compose run app "RAILS_ENV=production rails assets:precompile"

cache:
	docker-compose run app "rails tmp:cache:clear assets:clobber"

ssh:
	docker-compose run app /bin/bash

local-bundle:
	bundle install

stop-all:
	 docker stop $$(docker ps -q -a)

prune:
	@make stop-all
	docker volume prune

bump:
	@make local-bundle
	@make build
	@make upgrade
	@make migration
	@make cache
	@make precompile
	@make prod

init:
	@make create
	@make migration
	@make upgrade
	@make seed

build-no-cache:
	docker-compose build --no-cache
