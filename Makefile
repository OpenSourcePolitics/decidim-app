.PHONY: build upgrade migration up

migration:
	docker-compose run app "rails db:migrate"

upgrade:
	docker-compose run app "rake decidim:upgrade"

up:
	docker-compose up

prod:
	docker-compose -f docker-compose.prod.yml up

build:
	docker-compose build

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

bump:
	@make build
	@make upgrade
	@make migration
	@make cache
	@make precompile
	@make prod
